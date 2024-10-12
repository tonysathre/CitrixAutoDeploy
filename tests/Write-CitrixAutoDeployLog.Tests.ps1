# Test script for Write-CtxAutodeployLog function
Describe "Write-CtxAutodeployLog" {
    # Mock Write-EventLog cmdlet for testing
    Mock Write-EventLog {}

    Context "When CI environment variable is set" {
        BeforeAll { $env:CI = $true }
        AfterAll { Remove-Item Env:\CI }

        It "should return formatted log entry for Error entry type" {
            $Message = "Test error message"
            $EventId = 101
            $EntryType = [System.Diagnostics.EventLogEntryType]::Error
            
            $result = Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType
            $result | Should -Match "\[.*\] \[ERROR\] Test error message"
        }

        It "should return formatted log entry for Information entry type" {
            $Message = "Test info message"
            $EventId = 102
            $EntryType = [System.Diagnostics.EventLogEntryType]::Information
            
            $result = Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType
            $result | Should -Match "\[.*\] \[INFO\] Test info message"
        }

        It "should return formatted log entry for Warning entry type" {
            $Message = "Test warning message"
            $EventId = 103
            $EntryType = [System.Diagnostics.EventLogEntryType]::Warning
            
            $result = Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType
            $result | Should -Match "\[.*\] \[WARN\] Test warning message"
        }

        It "should return formatted log entry for FailureAudit entry type" {
            $Message = "Test audit failure"
            $EventId = 104
            $EntryType = [System.Diagnostics.EventLogEntryType]::FailureAudit
            
            $result = Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType
            $result | Should -Match "\[.*\] \[AUDIT_FAILURE\] Test audit failure"
        }

        It "should return formatted log entry for SuccessAudit entry type" {
            $Message = "Test audit success"
            $EventId = 105
            $EntryType = [System.Diagnostics.EventLogEntryType]::SuccessAudit
            
            $result = Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType
            $result | Should -Match "\[.*\] \[AUDIT_SUCCESS\] Test audit success"
        }
    }

    Context "When CI environment variable is not set" {
        BeforeAll { Remove-Item Env:\CI -ErrorAction SilentlyContinue }

        It "should call Write-EventLog with correct parameters for Error" {
            $Message = "Error log message"
            $EventId = 200
            $EntryType = [System.Diagnostics.EventLogEntryType]::Error
            
            Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType

            Assert-MockCalled -CommandName Write-EventLog -Exactly 1 -Scope It -ParameterFilter {
                $LogName -eq 'Citrix Autodeploy' -and
                $Source -eq 'Citrix Autodeploy' -and
                $Message -eq 'Error log message' -and
                $EventId -eq 200 -and
                $EntryType -eq [System.Diagnostics.EventLogEntryType]::Error
            }
        }

        It "should call Write-EventLog with correct parameters for Warning" {
            $Message = "Warning log message"
            $EventId = 201
            $EntryType = [System.Diagnostics.EventLogEntryType]::Warning
            
            Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType

            Assert-MockCalled -CommandName Write-EventLog -Exactly 1 -Scope It -ParameterFilter {
                $LogName -eq 'Citrix Autodeploy' -and
                $Source -eq 'Citrix Autodeploy' -and
                $Message -eq 'Warning log message' -and
                $EventId -eq 201 -and
                $EntryType -eq [System.Diagnostics.EventLogEntryType]::Warning
            }
        }

        It "should call Write-EventLog with correct parameters for Information" {
            $Message = "Info log message"
            $EventId = 202
            $EntryType = [System.Diagnostics.EventLogEntryType]::Information
            
            Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType

            Assert-MockCalled -CommandName Write-EventLog -Exactly 1 -Scope It -ParameterFilter {
                $LogName -eq 'Citrix Autodeploy' -and
                $Source -eq 'Citrix Autodeploy' -and
                $Message -eq 'Info log message' -and
                $EventId -eq 202 -and
                $EntryType -eq [System.Diagnostics.EventLogEntryType]::Information
            }
        }
    }
}
