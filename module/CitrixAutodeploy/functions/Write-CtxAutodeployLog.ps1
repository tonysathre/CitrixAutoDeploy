function Write-CtxAutodeployLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Message,

        [Parameter(Mandatory)]
        [int]$EventId,

        [Parameter(Mandatory)]
        [ValidateSet('Error', 'Information', 'Warning', 'FailureAudit', 'SuccessAudit')]
        [System.Diagnostics.EventLogEntryType]$EntryType
    )

    if ($env:CI) {
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
            'FailureAudit' {
                $Type = 'AUDIT_FAILURE'
            }
            'SuccessAudit' {
                $Type = 'AUDIT_SUCCESS'
            }
            default {
                $Type = 'INFO'
            }
        }

        return '[{0}] [{1}] {2}' -f [datetime]::Now, $Type, $Message
    }

    Write-EventLog -LogName 'Citrix Autodeploy' -Source 'Citrix Autodeploy' -Message $Message -EventId $EventId -EntryType $EntryType
}
