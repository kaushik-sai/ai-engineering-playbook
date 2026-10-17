#requires -Version 7.0
<#
.SYNOPSIS
    Claude Code PreToolUse hook for the Bash tool. Blocks dangerous shell commands.

.DESCRIPTION
    Reads the hook JSON from stdin and inspects tool_input.command.
    Exit 0 lets the command proceed. Exit 2 blocks it and the reason on stderr
    is shown to Claude. Invalid input fails closed (exit 2).

    The rules are data at the top of this file: extend $script:BlockRules for
    simple patterns, or the other variables for the branch and path checks.
    Hooks run with your permissions: review changes to this file like code.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Rule data. Edit here to extend the guard.
# ---------------------------------------------------------------------------

# Branches that must not be pushed to or hard-reset.
$script:ProtectedBranches = @('main', 'master')

# Targets that make a recursive delete a block (matched against each argument).
$script:DangerousDeleteTarget = '^(/|/\*|~|~/|~/\*|\$HOME|\$HOME/|\$HOME/\*|\$\{HOME\}|\$\{HOME\}/\*|\$env:USERPROFILE|\*|\./\*|\.|\./|\.\.|\.\./?\*?|/home|/home/\*|/etc|/usr|/var|/bin|[A-Za-z]:\\?)$'

# Verbs and redirects that write to or delete a file (a redirect to /dev/null or >&1 is not one).
$script:WriteVerb = '>(?!&\d|\s*/dev/null)|\btee\b|\bsed\b[^|;&\r\n]*\s(-[a-zA-Z]*i|--in-place)|\bperl\b[^|;&\r\n]*\s-[a-zA-Z]*i|\b(mv|cp|rm|ri|ln|dd|install|chmod|chown|truncate|Set-Content|Add-Content|Out-File|Remove-Item|Move-Item|Copy-Item)\b'

# Simple regex rules, matched against the whole command (case-insensitive).
# Optional Skip: whole-command regex that exempts the rule. Strip: first match is removed before matching.
$script:BlockRules = @(
    @{
        Id      = 'modify-guardrails'
        Pattern = '(?s)(?=.*\.claude[/\\](hooks[/\\]|settings(\.local)?\.json))(?=.*(' + $script:WriteVerb + ')).*'
        Reason  = 'Agents must not write to or delete their own hooks or settings.'
    }
    @{
        Id      = 'write-git-dir'
        Pattern = '(?s)(?=.*(?<![\w.-])\.git[/\\])(?=.*(' + $script:WriteVerb + ')).*'
        Reason  = 'Edit git state with git commands, not by writing into .git/.'
    }
    @{
        Id      = 'pipe-to-shell'
        Pattern = '\b(curl|wget|iwr|irm|Invoke-WebRequest|Invoke-RestMethod)\b[^\r\n]*\|\s*(sudo\s+)?(sh|bash|zsh|pwsh|powershell|iex|Invoke-Expression)\b'
        Reason  = 'Piping a download into a shell runs unreviewed code. Download the file, read it, then run it.'
    }
    @{
        Id      = 'shell-from-download'
        Pattern = '\b(sh|bash|zsh)\s+<\(\s*(curl|wget)\b|\b(iex|Invoke-Expression)\b[^\r\n]*\b(iwr|irm|curl|wget|Invoke-WebRequest|Invoke-RestMethod)\b'
        Reason  = 'Executing downloaded text directly runs unreviewed code.'
    }
    @{
        Id      = 'read-secret-file'
        Pattern = '(?<=^|[\s/"''=@<(])(\.env(?!\.(example|sample|template)\b)(\.[\w.-]+)?|[^\s/"''@<=(]*\.pem|id_rsa[\w.]*|id_ed25519[\w.]*|\.secrets/[^\s"'']*)(?=$|[\s"'';|&)])'
        Skip    = '^\s*cp\s+(-\S+\s+)*(\./)?\.env\.(example|sample|template)\s+(\./)?\.env\s*$'
        Strip   = '^\s*(grep|rg|Select-String)\s+((?!(?-i:-\S*f\b)|--file)-\S*\s+)*("[^"]*"|''[^'']*'')'
        Reason  = 'Reading .env, *.pem, SSH keys or .secrets/** would put secrets in the model context.'
    }
    @{
        Id      = 'dump-environment'
        Pattern = '(?m)(^|[;&|(]\s*|\bsudo\s+)(env|printenv)\s*(\||>|;|&|\)|$)|\bexport\s+-p\b|\bdeclare\s+-x\b|\b(Get-ChildItem|gci|ls|dir|Get-Item)\s+(-Path\s+)?env:\s*(\*|\||;|$)|\[Environment\]::GetEnvironmentVariables'
        Reason  = 'Printing all environment variables can expose tokens. Read a single named variable if you need it.'
    }
    @{
        Id      = 'terraform-apply-destroy'
        Pattern = '\b(terraform|tofu)\s+(-chdir=\S+\s+)?(apply|destroy)\b'
        Reason  = 'terraform apply and destroy change real infrastructure. Run plan, and let a human apply.'
    }
    @{
        Id      = 'kubectl-delete-prod'
        Pattern = '\bkubectl\b(?=[^\r\n]*\bdelete\b)(?=[^\r\n]*(\bprod|\bprd\b|production|\blive\b|--all-namespaces|\s-A\b|--all\b))'
        Reason  = 'kubectl delete against a production-like context or scope is not allowed for the agent.'
    }
    @{
        Id      = 'chmod-777'
        Pattern = '\bchmod\s+(-[a-zA-Z]+\s+)*(0?777|a\+rwx|ugo\+rwx)\b'
        Reason  = 'chmod 777 makes files world-writable. Use the least permission that works.'
    }
    @{
        Id      = 'disable-tests'
        Pattern = '\bInvoke-Pester\b[^;&|\r\n]*\s-Skip(\s|:|=|$)|\b(it|describe|test|context)\.skip\b|\bx(it|describe)\(|pytest\.mark\.skip'
        Reason  = 'Disabling or skipping tests hides failures. Fix the test or the code instead.'
    }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Exit-Block {
    param([string]$RuleId, [string]$Reason)
    [Console]::Error.WriteLine("Blocked by Guard-BashCommand [$RuleId]: $Reason")
    [Console]::Error.WriteLine('If this is really needed, ask the user to run it themselves.')
    exit 2
}

function Get-CurrentBranch {
    param([string]$Directory)
    if (-not $Directory -or -not (Test-Path -LiteralPath $Directory)) { $Directory = (Get-Location).Path }
    $branch = & git -C $Directory symbolic-ref --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $branch) { return $null }
    return ([string]$branch).Trim()
}

function Split-Segment {
    param([string]$Command)
    # Split on ; & | and newlines, so each simple command is checked on its own.
    $segments = New-Object System.Collections.Generic.List[object]
    foreach ($part in ($Command -split '[;&|\r\n]+')) {
        $text = $part.Trim()
        if (-not $text) { continue }
        $segments.Add(@($text -split '\s+' | ForEach-Object { $_.Trim('"', "'") } | Where-Object { $_ }))
    }
    return , $segments
}

function Get-GitArgument {
    # Returns @{ Sub = 'push'; Args = @(...) } for a token list that starts a git command, else $null.
    param([string[]]$Token)
    $i = 0
    while ($i -lt $Token.Count -and $Token[$i] -notmatch '(^|[/\\])git(\.exe)?$') { $i++ }
    if ($i -ge $Token.Count) { return $null }
    $i++
    while ($i -lt $Token.Count -and $Token[$i].StartsWith('-')) {
        if ($Token[$i] -in @('-C', '-c')) { $i += 2 } else { $i++ }
    }
    if ($i -ge $Token.Count) { return $null }
    $rest = if ($i + 1 -lt $Token.Count) { $Token[($i + 1)..($Token.Count - 1)] } else { @() }
    return @{ Sub = $Token[$i]; Args = @($rest) }
}

function Test-ProtectedBranch {
    param([string]$Name)
    return $Name -in $script:ProtectedBranches
}

function Test-DangerousDelete {
    # Looks at every rm / Remove-Item / ri token, so sudo, xargs, env and bash -c "..." do not hide it.
    param([string[]]$Token)
    for ($i = 0; $i -lt $Token.Count; $i++) {
        if ($Token[$i] -notmatch '(?i)(^|[/\\])(rm|Remove-Item|ri)(\.exe)?$') { continue }
        $isRm = $Token[$i] -cmatch '(^|[/\\])rm(\.exe)?$'
        $recursive = $false
        $targets = @()
        foreach ($t in ($Token | Select-Object -Skip ($i + 1))) {
            if ($t -match '(?i)^--recursive$|^-r(ec\w*)?(:\S*)?$' -and -not $isRm) { $recursive = $true }
            elseif ($isRm -and ($t -eq '--recursive' -or $t -cmatch '^-[a-zA-Z]*[rR][a-zA-Z]*$')) { $recursive = $true }
            elseif (-not $t.StartsWith('-')) { $targets += $t }
        }
        if (-not $recursive) { continue }
        foreach ($target in $targets) {
            if ($target -match $script:DangerousDeleteTarget) { return $true }
        }
    }
    return $false
}

function Test-GitPush {
    param([hashtable]$Git, [string]$Directory)
    $forced = $false
    $positional = @()
    foreach ($a in $Git.Args) {
        if ($a -match '^--force-with-lease(=.*)?$') { continue }
        if ($a -in @('--force', '--force-if-includes') -or $a -cmatch '^-[a-zA-Z]*f[a-zA-Z]*$') { $forced = $true }
        elseif ($a -in @('--mirror', '--all')) { Exit-Block 'git-push-mirror' "git push $a can overwrite or publish protected branches." }
        elseif (-not $a.StartsWith('-')) { $positional += $a }
    }
    if ($forced) { Exit-Block 'git-push-force' 'Force push is not allowed. Use --force-with-lease on a feature branch.' }
    $refspecs = @($positional | Select-Object -Skip 1)
    if ($refspecs.Count -eq 0 -or $refspecs -contains 'HEAD') {
        $branch = Get-CurrentBranch $Directory
        if (-not $branch -or (Test-ProtectedBranch $branch)) {
            Exit-Block 'git-push-protected' 'Pushing the current branch is blocked: it is a protected branch or could not be determined.'
        }
    }
    foreach ($spec in $refspecs) {
        if ($spec.StartsWith('+')) { Exit-Block 'git-push-force' 'A refspec starting with + is a force push.' }
        $dest = ($spec -split ':')[-1] -replace '^refs/heads/', ''
        if (Test-ProtectedBranch $dest) {
            Exit-Block 'git-push-protected' "Pushing to $dest is not allowed. Open a pull request from a feature branch."
        }
    }
}

function Test-Command {
    param([string]$Command, [string]$Directory)

    foreach ($rule in $script:BlockRules) {
        if ($rule.ContainsKey('Skip') -and $Command -match "(?i)$($rule.Skip)") { continue }
        $text = if ($rule.ContainsKey('Strip')) { [regex]::new("(?i)$($rule.Strip)").Replace($Command, '$1 ', 1) } else { $Command }
        if ($text -match "(?i)$($rule.Pattern)") { Exit-Block $rule.Id $rule.Reason }
    }

    foreach ($tokens in (Split-Segment $Command)) {
        if (Test-DangerousDelete $tokens) {
            Exit-Block 'recursive-delete' 'Recursive delete of /, ~, $HOME or a broad glob is not allowed. Name the exact directory.'
        }
        $git = Get-GitArgument $tokens
        if (-not $git) { continue }
        if ($git.Sub -eq 'push') { Test-GitPush $git $Directory }
        if ($git.Sub -eq 'reset' -and $git.Args -contains '--hard') {
            $branch = Get-CurrentBranch $Directory
            if (-not $branch -or (Test-ProtectedBranch $branch)) {
                Exit-Block 'git-reset-hard-main' 'git reset --hard on a protected branch (or an unknown branch) is blocked.'
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    $hookInput = $raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    [Console]::Error.WriteLine('Blocked by Guard-BashCommand [bad-input]: hook input is not valid JSON (fail closed).')
    exit 2
}

if ($null -eq $hookInput -or $hookInput -isnot [pscustomobject]) {
    [Console]::Error.WriteLine('Blocked by Guard-BashCommand [bad-input]: hook input is not a JSON object (fail closed).')
    exit 2
}

$command = $null
if ($hookInput.PSObject.Properties['tool_input'] -and $hookInput.tool_input -and $hookInput.tool_input.PSObject.Properties['command']) {
    $command = [string]$hookInput.tool_input.command
}
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

$directory = $null
if ($hookInput.PSObject.Properties['cwd']) { $directory = [string]$hookInput.cwd }

try {
    Test-Command -Command $command -Directory $directory
}
catch {
    [Console]::Error.WriteLine("Blocked by Guard-BashCommand [internal-error]: $($_.Exception.Message) (fail closed).")
    exit 2
}
exit 0
