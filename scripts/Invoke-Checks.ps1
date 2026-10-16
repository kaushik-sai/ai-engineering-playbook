#requires -Version 7.0
<#
.SYNOPSIS
    Runs the same lint and test checks as CI (PowerShell part), locally.

.DESCRIPTION
    1. PSScriptAnalyzer over templates, tests and scripts: any finding fails.
    2. Pester tests under tests/.
    3. jq empty on every *.json file (skipped with a warning if jq is missing).
    4. markdownlint-cli2 0.23.3 on every *.md file (skipped with a warning if npx is missing).
    5. design-system/build_tokens.py --check (skipped with a warning if python3 is missing).
    Link check, secret scan and actionlint run in CI only; see CONTRIBUTING.md.
    Required modules: Pester 5.7.1 and PSScriptAnalyzer 1.24.0 (same as CI).

.EXAMPLE
    pwsh ./scripts/Invoke-Checks.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$failed = $false

foreach ($module in @{ Pester = '5.7.1'; PSScriptAnalyzer = '1.24.0' }.GetEnumerator()) {
    $found = Get-Module -ListAvailable -Name $module.Key | Where-Object { $_.Version -eq [version]$module.Value }
    if (-not $found) {
        Write-Warning "$($module.Key) $($module.Value) is not installed. Run: Install-Module $($module.Key) -RequiredVersion $($module.Value) -Scope CurrentUser"
    }
}

Write-Output '== PSScriptAnalyzer =='
$settings = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
$findings = @()
foreach ($folder in 'templates', 'tests', 'scripts') {
    $findings += @(Invoke-ScriptAnalyzer -Path (Join-Path $repoRoot $folder) -Recurse -Settings $settings)
}
if ($findings.Count -gt 0) {
    $findings | Format-Table RuleName, Severity, ScriptName, Line, Message -AutoSize | Out-String | Write-Output
    $failed = $true
}
Write-Output "Findings: $($findings.Count)"

Write-Output '== Pester =='
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $repoRoot 'tests'
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Normal'
$result = Invoke-Pester -Configuration $config
if ($result.FailedCount -gt 0 -or $result.TotalCount -eq 0) { $failed = $true }

Write-Output '== JSON =='
$jq = Get-Command jq -ErrorAction SilentlyContinue
if ($jq) {
    $jsonFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter '*.json' -File |
        Where-Object { $_.FullName -notmatch '[\\/](node_modules|\.git)[\\/]' }
    foreach ($file in $jsonFiles) {
        & jq empty $file.FullName 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Invalid JSON: $($file.FullName)" -ErrorAction Continue
            $failed = $true
        }
    }
    Write-Output "Checked $(@($jsonFiles).Count) JSON file(s)."
}
else {
    Write-Warning 'jq not found: JSON check skipped (CI will run it).'
}

Write-Output '== Markdown =='
if (Get-Command npx -ErrorAction SilentlyContinue) {
    Push-Location $repoRoot
    try {
        & npx --yes markdownlint-cli2@0.23.3 '**/*.md' '#node_modules'
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
    finally { Pop-Location }
}
else {
    Write-Warning 'npx not found: markdown lint skipped (CI will run it).'
}

Write-Output '== Design tokens =='
$python = Get-Command python3, python -ErrorAction SilentlyContinue | Select-Object -First 1
if ($python) {
    & $python.Source (Join-Path $repoRoot 'design-system/build_tokens.py') --check
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}
else {
    Write-Warning 'python3 not found: token check skipped (CI will run it).'
}

if ($failed) {
    Write-Output 'RESULT: FAILED'
    exit 1
}
Write-Output 'RESULT: OK'
exit 0
