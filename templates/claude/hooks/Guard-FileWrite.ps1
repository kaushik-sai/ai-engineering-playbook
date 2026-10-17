#requires -Version 7.0
<#
.SYNOPSIS
    Claude Code PreToolUse hook for Write, Edit, MultiEdit and NotebookEdit. Blocks writes to
    protected paths and writes whose content looks like a secret.

.DESCRIPTION
    Exit 0 lets the write proceed. Exit 2 blocks it and the reason on stderr is
    shown to Claude. Invalid input fails closed (exit 2). Agents must not edit
    their own guardrails, so .claude/settings*.json and .claude/hooks/** are
    protected too. The secret value is never echoed back.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Rule data. Paths are normalised to forward slashes before matching.
# ---------------------------------------------------------------------------

$script:ProtectedPath = @(
    @{ Id = 'env-file'; Pattern = '(^|/)\.env(?!\.(example|sample|template)$)(\.[^/]+)?$'; Reason = 'Environment files hold secrets.' }
    @{ Id = 'key-file'; Pattern = '\.(pem|key)$|(^|/)id_(rsa|ed25519)[^/]*$'; Reason = 'Key files hold secrets.' }
    @{ Id = 'secrets-dir'; Pattern = '(^|/)\.secrets(/|$)'; Reason = 'The .secrets directory is off limits.' }
    @{ Id = 'git-dir'; Pattern = '(^|/)\.git(/|$)'; Reason = 'Edit git state with git commands, not by writing files.' }
    @{ Id = 'claude-settings'; Pattern = '(^|/)\.claude/settings(\.local)?\.json$'; Reason = 'Agents must not edit their own permissions.' }
    @{ Id = 'claude-hooks'; Pattern = '(^|/)\.claude/hooks(/|$)'; Reason = 'Agents must not edit their own guardrail scripts.' }
)

$script:SecretPattern = @(
    @{ Id = 'aws-access-key'; Pattern = '\bAKIA[0-9A-Z]{16}\b' }
    @{ Id = 'github-token'; Pattern = '\bgh[pousr]_[A-Za-z0-9]{36,}\b' }
    @{ Id = 'github-pat'; Pattern = '\bgithub_pat_[A-Za-z0-9_]{22,}\b' }
    @{ Id = 'private-key'; Pattern = '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY' }
    @{ Id = 'slack-token'; Pattern = '\bxox[abprs]-[A-Za-z0-9-]{10,}' }
    @{ Id = 'anthropic-key'; Pattern = '\bsk-ant-[A-Za-z0-9_-]{20,}' }
    @{ Id = 'password-assignment'; Pattern = '(?i)\b(password|passwd|pwd)[''"]?\s*[:=]\s*[''"][^''"\s]{12,}[''"]' }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Exit-Block {
    param([string]$RuleId, [string]$Reason)
    [Console]::Error.WriteLine("Blocked by Guard-FileWrite [$RuleId]: $Reason")
    exit 2
}

function ConvertTo-NormalPath {
    param([string]$Path, [string]$BaseDirectory)
    $base = if ($BaseDirectory) { $BaseDirectory } else { (Get-Location).Path }
    try { $full = [System.IO.Path]::GetFullPath($Path, $base) } catch { $full = $Path }
    return ($full -replace '\\', '/')
}

function Get-WrittenText {
    param($ToolInput)
    $text = New-Object System.Collections.Generic.List[string]
    foreach ($name in 'content', 'new_string', 'new_source') {
        if ($ToolInput.PSObject.Properties[$name] -and $ToolInput.$name) { $text.Add([string]$ToolInput.$name) }
    }
    if ($ToolInput.PSObject.Properties['edits'] -and $ToolInput.edits) {
        foreach ($edit in $ToolInput.edits) {
            if ($edit.PSObject.Properties['new_string'] -and $edit.new_string) { $text.Add([string]$edit.new_string) }
        }
    }
    return $text
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    $hookInput = $raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    [Console]::Error.WriteLine('Blocked by Guard-FileWrite [bad-input]: hook input is not valid JSON (fail closed).')
    exit 2
}

if ($null -eq $hookInput -or $hookInput -isnot [pscustomobject]) {
    [Console]::Error.WriteLine('Blocked by Guard-FileWrite [bad-input]: hook input is not a JSON object (fail closed).')
    exit 2
}

try {
    if (-not ($hookInput.PSObject.Properties['tool_input'] -and $hookInput.tool_input)) { exit 0 }
    $toolInput = $hookInput.tool_input
    $cwd = if ($hookInput.PSObject.Properties['cwd']) { [string]$hookInput.cwd } else { $null }

    $filePath = $null
    foreach ($name in 'file_path', 'path', 'notebook_path') {
        if ($toolInput.PSObject.Properties[$name] -and $toolInput.$name) { $filePath = [string]$toolInput.$name; break }
    }

    if ($filePath) {
        $normal = ConvertTo-NormalPath -Path $filePath -BaseDirectory $cwd
        foreach ($rule in $script:ProtectedPath) {
            if ($normal -match $rule.Pattern) { Exit-Block $rule.Id "$($rule.Reason) Path: $filePath" }
        }
    }

    foreach ($text in (Get-WrittenText $toolInput)) {
        foreach ($rule in $script:SecretPattern) {
            if ($text -match $rule.Pattern) {
                Exit-Block "secret-$($rule.Id)" 'The content looks like a secret (value not shown). Use an environment variable or a secret store.'
            }
        }
    }
}
catch {
    [Console]::Error.WriteLine("Blocked by Guard-FileWrite [internal-error]: $($_.Exception.Message) (fail closed).")
    exit 2
}
exit 0
