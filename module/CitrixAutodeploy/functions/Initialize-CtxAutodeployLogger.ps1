function Initialize-CtxAutodeployLogger {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
        [string]$LogLevel = 'Information',

        [Parameter()]
        [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE,

        [Parameter()]
        [string]$OutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] {Message:lj}{NewLine}{Exception}'
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)
    $Logger = New-Logger |
        Add-SinkConsole -OutputTemplate $OutputTemplate |
        Set-MinimumLevel -Value $LogLevel -ToPreference

    if ($LogFile) {
        Write-VerboseLog -Message "Adding file sink {LogFile} to logger" -PropertyValues $LogFile
        $Logger = $Logger | Add-SinkFile -Path $LogFile -OutputTemplate $OutputTemplate
    }

    Write-DebugLog -Message "Starting logger with parameters: {Logger}" -PropertyValues 'StartLogger', ($Logger | Out-String)
    try {
        Start-Logger -LoggerConfig $Logger -PassThru
    }
    catch {
        Write-ErrorLog -Message "Failed to start logger" -Exception $_.Exception -ErrorRecord $_
    }

    return $Logger
}
