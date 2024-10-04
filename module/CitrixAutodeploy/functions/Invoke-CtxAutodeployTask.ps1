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
        Write-CtxAutodeployLog -Message "$($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message): $($_.Exception.InnerException)" -EventId 1 -EntryType Error
    }
}
