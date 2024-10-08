function Initialize-CtxAutodeployLogger {
    [CmdletBinding()]
    [OutputType([Serilog.Core.Logger])]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
        [string]$LogLevel = 'Information',

        [Parameter()]
        [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE,

        [Parameter()]
        [string]$LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] {Message:lj}{NewLine}{Exception}'
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)
    $LoggerConfig = New-Logger |
        Add-SinkConsole -OutputTemplate $LogOutputTemplate |
        Set-MinimumLevel -Value $LogLevel -ToPreference

    if ($LogFile) {
        Write-VerboseLog -Message "Adding file sink {LogFile} to logger" -PropertyValues $LogFile
        $LoggerConfig = $LoggerConfig | Add-SinkFile -Path $LogFile -OutputTemplate $LogOutputTemplate
    }

    Write-DebugLog -Message 'Starting logger' -PropertyValues $LoggerConfig
    try {
        $Logger = Start-Logger -LoggerConfig $LoggerConfig -SetAsDefault -PassThru
    }
    catch {
        Write-ErrorLog -Message "Failed to start logger" -Exception $_.Exception -ErrorRecord $_
    }

    return $Logger
}
