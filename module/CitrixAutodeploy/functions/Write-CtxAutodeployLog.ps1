function Write-CtxAutodeployLog {
    [CmdletBinding()]
    param(
        [psobject]$Message,
        [int]$EventId,
        [System.Diagnostics.EventLogEntryType]$EntryType
    )

    if ($env:CI) {
        if ($EntryType -eq [System.Diagnostics.EventLogEntryType]::Error) {
            Write-Error $Message
        } else {
            Write-Host $Message
        }
    } else {
        Write-EventLog -LogName 'Citrix Autodeploy' -Source 'Citrix Autodeploy' -Message $Message -EventId $EventId -EntryType $EntryType
    }
}
