function Write-CtxAutodeployLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Message,

        [Parameter(Mandatory)]
        [int]$EventId,

        [Parameter(Mandatory)]
        [ValidateSet('Error', 'Information', 'Warning')]
        [System.Diagnostics.EventLogEntryType]$EntryType
    )

    switch ([System.Diagnostics.EventLogEntryType]$EntryType) {
        'Error' {
            $Type = 'ERROR'
        }
        'Information' {
            $Type = 'INFO'
        }
        'Warning' {
            $Type = 'WARN'
        }
        default {
            $Type = 'INFO'
        }
    }

    '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-mm-dd HH:mm:ss.fff'), $Type, $Message
}
