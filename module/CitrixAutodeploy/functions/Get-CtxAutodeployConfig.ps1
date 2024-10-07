function Get-CtxAutodeployConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$FilePath = $env:CITRIX_AUTODEPLOY_CONFIG
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    Write-InfoLog -Message "Loading configuration from file: '{FilePath}'" -PropertyValues $FilePath
    try {
        $Config = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    }
    catch {
        Write-ErrorLog -Message "Failed to load configuration from file '{FilePath}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $ConfigFilePath
        throw
    }

    return $Config
}
