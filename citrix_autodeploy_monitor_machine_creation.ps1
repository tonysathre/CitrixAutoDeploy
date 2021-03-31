$Json = Get-Content $PSScriptRoot\citrix_autodeploy_config_email.json | ConvertFrom-Json
$Event = Get-EventLog -LogName 'Citrix Autodeploy' -Newest 1 -InstanceId 3
$Body = $Event.Message
$From = $Json.From
$To = $Json.To
$Subject = 'Citrix Autodeploy Machine Created'
$SmtpServer = $Json.SmtpServer
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SmtpServer