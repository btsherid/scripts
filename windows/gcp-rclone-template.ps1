Set-Location <<CHANGEME>>
New-PSDrive -Name "S" -PSProvider "FileSystem" -Root "<<Backup Log File Location>>"
$servername = "<<CHANGEME>>"
$path = "<<CHANGEME>>"
$date = Get-Date -Format "yyyy-MM-dd-HHmmss"


C:\Rclone\rclone.exe sync --local-no-check-updated --progress --skip-links --exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/** .\ <<rclone to GCP connector path>> | Out-File -FilePath S:\${path}\${path}_$date
$status = $?
$command = Get-History -Count 1  

if($status) {
	Send-MailMessage -From Admin@$servername -To '<<my email address>>' -Subject 'GCP Rclone completion' -SmtpServer relay.example.com -Body "GCP rclone sync for $path finished successfully.`n`nLog file is located at <<NFS storage>>/${path}/${path}_$date"
}else {
    Send-MailMessage -From Admin@$servername -To '<<my email address>>' -Subject 'GCP Rclone error' -SmtpServer relay.example.com -Body "GCP rclone sync for $path failed.`n`nLog file is located at <<NFS storage>>/${path}/${path}_$date"
}
