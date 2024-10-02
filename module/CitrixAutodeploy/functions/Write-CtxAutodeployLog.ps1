function Write-CtxAutodeployLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Message,

        [Parameter(Mandatory)]
        [int]$EventId,

        [Parameter(Mandatory)]
        [System.Diagnostics.EventLogEntryType]$EntryType
    )

    if ($env:CI) {
        if ($EntryType -eq [System.Diagnostics.EventLogEntryType]::Error) {
            Write-Error ('{0} {1}' -f "[$([datetime]::Now)]", $Message)
        } else {
            Write-Host ('{0} {1}' -f "[$([datetime]::Now)]", $Message)
        }

        return
    }

    Write-EventLog -LogName 'Citrix Autodeploy' -Source 'Citrix Autodeploy' -Message $Message -EventId $EventId -EntryType $EntryType
}
