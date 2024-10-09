function Start-CtxHighLevelLogger {
    [CmdletBinding()]
    [OutputType([Citrix.ConfigurationLogging.Sdk.HighLevelOperation])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [string]$Source = 'Citrix Autodeploy',

        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    $Logging = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source $Source -StartTime ([datetime]::Now) -Text $Text -OperationType AdminActivity
    Write-DebugLog -Message "High-level logging operation started with Id: {Logging}" -PropertyValues $Logging.Id

    return $Logging
}
