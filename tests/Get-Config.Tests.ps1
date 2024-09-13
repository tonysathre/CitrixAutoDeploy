Describe 'Get-Config' {
    It 'Should return configuration object if file exists' {
        $FilePath = "${PSScriptRoot}/test_config.json"
        $Config = Get-Config -FilePath $FilePath
        $Config.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'

        #Remove-Item -Path $FilePath
    }

    It 'Should throw error if file does not exist' {
        $FilePath = "${PSScriptRoot}/non_existent_config.json"
        { Get-Config -FilePath $FilePath -ErrorAction SilentlyContinue -ErrorVariable Errors } | Should -Throw
    }
}