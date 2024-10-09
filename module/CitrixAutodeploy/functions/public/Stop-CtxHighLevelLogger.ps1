function Stop-CtxHighLevelLogger {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$Logging,

        [Parameter(Mandatory)]
        [bool]$IsSuccessful
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime ([datetime]::Now) -IsSuccessful $IsSuccessful
    Write-DebugLog -Message "High-level logging operation with Id: {Logging} stopped" -PropertyValues $Logging.Id
}
