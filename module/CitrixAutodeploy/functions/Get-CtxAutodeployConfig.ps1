function Get-CtxAutodeployConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FilePath
    )

    try {
        if (Test-Path $FilePath) {
            return Get-Content $FilePath -Raw | ConvertFrom-Json
        } else {
            throw "Configuration file '${FilePath}' not found."
        }
    }
    catch {
        Write-CtxAutodeployLog -Message "$($_.Exception.Message)`n`n$($_.Exception.StackTrace)" -EventId 1 -EntryType Error
        throw $_.Exception
    }
}
