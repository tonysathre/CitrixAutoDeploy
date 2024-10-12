function Initialize-CtxAutodeployEnv {
    [CmdletBinding()]
    [OutputType([void])]
    param ()

    $Modules = @(
        "Citrix.ADIdentity.Commands",
        "Citrix.Broker.Commands",
        "Citrix.ConfigurationLogging.Commands",
        "Citrix.MachineCreation.Commands"
    )

    Write-VerboseLog -Message "Function {MyCommand} called" -PropertyValues $MyInvocation.MyCommand

    try {
        $Modules | Import-Module -DisableNameChecking -Force -ErrorAction Stop -WarningAction SilentlyContinue 4> $null
    }
    catch {
        Write-ErrorLog -Message "Failed to import module: {0}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $Modules
        throw
    }
}