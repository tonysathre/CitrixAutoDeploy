$Event = Get-EventLog -LogName 'Citrix Autodeploy' -Newest 1 -InstanceId 3
$Body = $Event.Message
$From = 'CitrixAutodeploy@example.com'
$To = @('citrixadmin1@example.com', 'citrixadmin2@example.com')
$Subject = 'Citrix Autodeploy Machine Created'
$SmtpServer = 'smtp.example.com'
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SmtpServer