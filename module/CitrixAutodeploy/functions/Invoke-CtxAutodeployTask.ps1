function Invoke-CtxAutodeployTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Task,

        [Parameter(Mandatory)]
        [PSCustomObject]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [string]$Context,

        [Parameter(Mandatory)]
        [Validateset('Pre', 'Post')]
        [string]$Type
    )

    try {
        Write-CtxAutodeployLog -Message "Executing ${Type}-task script '${Task}' for '${Context}'" -EventId 6 -EntryType Information
        $Output = . $Task
        Write-CtxAutodeployLog -Message "${Type}-task output: ${Output}" -EventId 8 -EntryType Information
    }
    catch {
        Write-CtxAutodeployLog -Message "Error occurred in ${Type}-task for machine '${Context}'`n`n$($_.Exception.Message)`n`n$($_.Exception.StackTrace)" -EventId 1 -EntryType Error
    }

    return $Output
}
