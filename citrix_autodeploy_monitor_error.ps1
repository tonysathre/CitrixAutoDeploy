$Event = Get-EventLog -LogName 'Citrix Powershell Autodeploy' -Newest 1 -InstanceId 1
$Body = $Event.Message
$From = 'CitrixAutodeploy@example.com'
$To = @('citrixadmin1@example.com', 'citrixadmin2@example.com')
$Subject = 'Citrix Autodeploy Error Occurred'
$SmtpServer = 'smtp.example.com'
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SmtpServer

# Disable scheduled task if error occurs
Get-ScheduledTask -TaskName 'Citrix Autodeploy Monitor' | Stop-ScheduledTask
Disable-ScheduledTask -TaskName 'Citrix Autodeploy Monitor'