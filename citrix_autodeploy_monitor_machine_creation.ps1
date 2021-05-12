$Json = Get-Content $PSScriptRoot\citrix_autodeploy_config_email.json | ConvertFrom-Json
$Event = Get-EventLog -LogName 'Citrix Autodeploy' -Newest 1 -InstanceId 3

$MailParams = @{
    SmtpServer = $Json.SmtpServer
    To         = $Json.To
    From       = $Json.From
    Subject    = 'Citrix Autodeploy Machine Created'
    Body       = $Event.Message
}

Send-MailMessage @MailParams
