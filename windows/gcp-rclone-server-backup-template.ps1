Set-Location <<CHANGEME>>
$date = Get-Date -Format "yyyy-MM-dd-HHmmss"
$servername = "<<CHANGEME>>"

.\rclone.exe sync --local-no-check-updated --ignore-checksum --ignore-size --progress --skip-links --exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/** --exclude /AppData/** --exclude **.dat**  --exclude **.DAT** --exclude /Windows/** --exclude /ProgramData/** --exclude **Recycle.Bin/** --exclude "System Volume Information/**" C:\ <<rclone gcp connector storage path>> | Out-File -FilePath .\$servername\${servername}_$date
$status = $?
$command = Get-History -Count 1  

if($status) {
	Send-MailMessage -From Admin@$servername -To '<<my email address>>' -Subject 'GCP Rclone completion' -SmtpServer relay.example.comu -Body "GCP rclone sync for $servername finished successfully.`n`nLog file is located at <<NFS Storage>>/$servername/${servername}_$date"
}else {
    Send-MailMessage -From Admin@$servername -To '<<my email address>>' -Subject 'GCP Rclone error' -SmtpServer relay.example.com -Body "GCP rclone sync for $servername failed.`n`nLog file is located at <<NFS Storage>>/$servername/${servername}_$date"
}
