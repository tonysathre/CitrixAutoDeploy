Describe 'Get-CtxAutodeployConfig' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    It 'Should return configuration object if file exists' {
        $FilePath = "${PSScriptRoot}/test_config.json"
        $Config = Get-CtxAutodeployConfig -FilePath $FilePath
        $Config.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'

        #Remove-Item -Path $FilePath
    }

    It 'Should throw error if file does not exist' {
        $FilePath = "${PSScriptRoot}/non_existent_config.json"
        { Get-CtxAutodeployConfig -FilePath $FilePath -ErrorAction SilentlyContinue -ErrorVariable Errors } | Should -Throw # suppress error message so it doesn't pollute our terminal
    }
}
