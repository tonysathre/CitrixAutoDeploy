Import-Module PowerShellGet -ErrorAction Stop

$BasePath = "${PSScriptRoot}\module\CitrixAutodeploy"
$NestedModules = (Get-ChildItem ${BasePath}\functions\*.ps1).Name | ForEach-Object { ".\functions\$_" }
$FunctionsToExport = (Get-ChildItem ${BasePath}\functions\*.ps1).Name -replace '\.ps1$'

Update-ModuleManifest -Path ${BasePath}\CitrixAutodeploy.psd1 -NestedModules $NestedModules -FunctionsToExport $FunctionsToExport