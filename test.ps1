#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.5.0'}

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Diagnostic', 'Detailed', 'Normal', 'Minimal', 'None')]
    [string]$Output = 'Normal',

    [Parameter(Mandatory = $false)]
    [string]$Path = "${PSScriptRoot}\tests"
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue

$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Output.Verbosity = $Output
$PesterConfiguration.Run.Path = $Path

Invoke-Pester -Configuration $PesterConfiguration
