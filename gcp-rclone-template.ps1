Set-Location <<CHANGEME>>
New-PSDrive -Name "S" -PSProvider "FileSystem" -Root "\\172.27.142.70\lnp1\alldata\netbackup\windows-gcp-backup-logs"
$servername = "<<CHANGEME>>"
$path = "<<CHANGEME>>"
$date = Get-Date -Format "yyyy-MM-dd-HHmmss"


C:\Rclone\rclone.exe sync --local-no-check-updated --progress --skip-links --exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/** .\ lbg-gcp://lccc-gcp-archive/<<CHANGEME>>/ | Out-File -FilePath S:\${path}\${path}_$date
$status = $?
$command = Get-History -Count 1  
$time = $command.EndExecutionTime - $command.StartExecutionTime
if($status) {
	Send-MailMessage -From Admin@$servername -To 'btsherid@ad.unc.edu' -Subject 'GCP Rclone completion' -SmtpServer relay.unc.edu -Body "GCP rclone sync for $path finished successfully in $time.`n`nLog file is located at /datastore/serverdepot/netbackup/gcp-rsync-logs/${path}/${path}_$date"
}else {
    Send-MailMessage -From Admin@$servername -To 'btsherid@ad.unc.edu' -Subject 'GCP Rclone error' -SmtpServer relay.unc.edu -Body "GCP rclone sync for $path failed.`n`nLog file is located at /datastore/serverdepot/netbackup/gcp-rsync-logs/${path}/${path}_$date"
}
