#requires -Version 7.0
<#
.SYNOPSIS
    Claude Code PostToolUse hook. Appends one JSON line per tool call to
    $CLAUDE_PROJECT_DIR/.claude/audit/tool-use.jsonl.

.DESCRIPTION
    Logs: ts (UTC), session_id, tool_name and a short summary (command truncated
    to 200 characters, or the file path). File contents are never logged and the
    summary is redacted with the same secret patterns as Guard-FileWrite.
    This hook never blocks: it always exits 0, even on errors.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SecretPattern = @(
    '\bAKIA[0-9A-Z]{16}\b'
    '\bgh[pousr]_[A-Za-z0-9]{36,}\b'
    '\bgithub_pat_[A-Za-z0-9_]{22,}\b'
    '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY[A-Za-z0-9 +/=-]*'
    '\bxox[abprs]-[A-Za-z0-9-]{10,}'
    '\bsk-ant-[A-Za-z0-9_-]{20,}'
    '(?i)\bBearer\s+\S+'
    'eyJ[\w-]+\.[\w-]+\.[\w-]*'
    '(?i)(?<!\S)--?(password|passwd|pass|token|secret|api-?key)(=|\s+)\S+'
    '(?<!\S)-p\s+\S+'
    '(?i)\b(password|passwd|pwd)\s*[:=]\s*[''"]?[^\s''"$<{%(][^\s''"]{11,}'
)
$script:MaxSummary = 200

function Hide-Secret {
    param([string]$Text)
    foreach ($pattern in $script:SecretPattern) { $Text = [regex]::Replace($Text, $pattern, '[REDACTED]') }
    return $Text
}

try {
    $raw = [Console]::In.ReadToEnd()
    $hookInput = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($hookInput -isnot [pscustomobject]) { exit 0 }

    $toolInput = if ($hookInput.PSObject.Properties['tool_input']) { $hookInput.tool_input } else { $null }
    $summary = ''
    if ($toolInput -is [pscustomobject]) {
        foreach ($name in 'command', 'file_path', 'notebook_path', 'path', 'pattern', 'url') {
            if ($toolInput.PSObject.Properties[$name] -and $toolInput.$name) { $summary = [string]$toolInput.$name; break }
        }
    }
    $summary = Hide-Secret $summary
    if ($summary.Length -gt $script:MaxSummary) { $summary = $summary.Substring(0, $script:MaxSummary) }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if (-not $projectDir -and $hookInput.PSObject.Properties['cwd']) { $projectDir = [string]$hookInput.cwd }
    if (-not $projectDir) { $projectDir = (Get-Location).Path }

    $auditDir = Join-Path $projectDir '.claude/audit'
    [void](New-Item -ItemType Directory -Path $auditDir -Force)

    $entry = [ordered]@{
        ts         = [DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'")
        session_id = if ($hookInput.PSObject.Properties['session_id']) { [string]$hookInput.session_id } else { '' }
        tool_name  = if ($hookInput.PSObject.Properties['tool_name']) { [string]$hookInput.tool_name } else { '' }
        summary    = $summary
    }
    $line = ($entry | ConvertTo-Json -Compress) + "`n"
    [System.IO.File]::AppendAllText((Join-Path $auditDir 'tool-use.jsonl'), $line, [System.Text.UTF8Encoding]::new($false))
}
catch {
    # Never block the agent because logging failed.
    [Console]::Error.WriteLine("Write-AuditLog: $($_.Exception.Message)")
}
exit 0
