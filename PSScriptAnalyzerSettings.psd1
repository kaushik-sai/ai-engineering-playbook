# PSScriptAnalyzer settings for the whole repo.
# Any finding (Error, Warning or Information) fails the build: the target is zero findings.
@{
    Severity            = @('Error', 'Warning', 'Information')
    IncludeDefaultRules = $true
    Rules               = @{
        PSUseCompatibleSyntax      = @{
            Enable         = $true
            # Scripts must run on PowerShell 7 on Windows, Linux and macOS.
            TargetVersions = @('7.0')
        }
        PSPlaceOpenBrace           = @{
            Enable     = $true
            OnSameLine = $true
        }
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }
    }
}
