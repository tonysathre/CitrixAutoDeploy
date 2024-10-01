Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop

$BasePath          = "${PSScriptRoot}\module\CitrixAutodeploy"
$NestedModules     = (Get-ChildItem ${BasePath}\functions\*.ps1).Name | ForEach-Object { ".\functions\$_" }
$FunctionsToExport = (Get-ChildItem ${BasePath}\functions\*.ps1).Name -replace '\.ps1$'
$Author            = 'Tony Sathre'
$CompanyName       = 'Tony Sathre'
$Description       = 'This module is used to automate the deployment of Citrix virtual desktops.'


$ModuleManifest = @{
    Author            = $Author
    CompanyName       = $CompanyName
    Description       = $Description
    Path              = "${BasePath}\CitrixAutodeploy.psd1"
    FunctionsToExport = $FunctionsToExport
    NestedModules     = $NestedModules
}

Update-ModuleManifest @ModuleManifest


