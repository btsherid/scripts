#!/bin/bash
ausearch="/sbin/ausearch"
aureport="/sbin/aureport"

truncate -s 0 /root/audit_email
truncate -s 0 /root/audit_email_attachment.txt

start="$(date "+%x %H:%M:%S" --date "-30 min")"
rsyslog="$($ausearch --input-logs --start $start -k rsyslogconf 2>/dev/null | $aureport -f -i | tail -n+6)"
oncoreapp="$($ausearch --input-logs --start $start -k oncoreappconf 2>/dev/null | $aureport -f -i | tail -n+6)"
cron_files="$($ausearch --input-logs --start $start -k cron 2>/dev/null | $aureport -f -i | tail -n+6)"
#failed_logins_total="$($aureport --input-logs --start $start -l --failed 2>/dev/null | tail -n+6)"
#failed_logins="$(echo $failed_logins_total | grep -v <monitoring server IP>)"
failed_logins="$($aureport --input-logs --start $start -l --failed 2>/dev/null | tail -n+6 | grep -v <monitoring server IP> | grep -v <monitoring server private IP> | grep -v <first two octets of scanning subnet> | grep -v interest | grep -v -e '^$' | wc -l)"
failed_authentications="$($aureport --input-logs --start $start -au --failed 2>/dev/null | tail -n+6 | grep -v <monitoring server IP> | grep -v <monitoring server private IP> | grep -v <first two octets of scanning subnet> | grep -v interest | grep -v -e '^$' | wc -l)"

if ! [[ "$rsyslog" == *"interest"* ]]; then
        rsyslog_events="$($ausearch --input-logs --start $start -k rsyslogconf 2>/dev/null | $aureport -f -i | tail -n+6 | wc -l)"
        echo "rsyslog.conf events: $rsyslog_events" >> /root/audit_email
        echo "======rsyslog.conf Events======" >> /root/audit_email_attachment.txt
        $ausearch --input-logs --start $start -k rsyslogconf 2>/dev/null | $aureport -f -i | tail -n+6 >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
fi

if ! [[ "$oncoreapp" == *"interest"* ]]; then
        oncoreapp_events="$($ausearch --input-logs --start $start -k oncoreappconf 2>/dev/null | $aureport -f -i | tail -n+6 | wc -l)"
        echo "OnCore application.conf events: $oncoreapp_events" >> /root/audit_email
        echo "======/opt/forte/oncore/configuration/application.conf Events======" >> /root/audit_email_attachment.txt
        $ausearch --input-logs --start $start -k oncoreappconf 2>/dev/null | $aureport -f -i >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
fi

if ! [[ "$cron_files" == *"interest"* ]]; then
        cron_events="$($ausearch --input-logs --start $start -k cron 2>/dev/null | $aureport -f -i | tail -n+6 | wc -l)"
        echo "cron File Events: $cron_events" >> /root/audit_email
        echo "======cron file Events======" >> /root/audit_email_attachment.txt
        $ausearch --input-logs --start $start -k cron 2>/dev/null | $aureport -f -i >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
fi

if [ "$failed_logins" -gt "0" ]; then
        login_events="$($aureport --input-logs --start $start -l --failed 2>/dev/null | tail -n+6 | grep -v <monitoring server IP> | grep -v <monitoring server private IP> | grep -v <first two octets of scanning subnet> | wc -l)"
        echo "Failed Logins: $login_events" >> /root/audit_email
        echo "======Failed Logins======" >> /root/audit_email_attachment.txt
        $aureport --input-logs --start $start -l --failed 2>/dev/null | grep -v <monitoring server IP> >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
fi

if [ "$failed_authentications" -gt "0" ]; then
        authentication_events="$($aureport --input-logs --start $start -au --failed 2>/dev/null | tail -n+6 | grep -v <monitoring server IP> | grep -v <monitoring server private IP> | grep -v <first two octets of scanning subnet> | wc -l)"
        echo "Failed Authentications: $authentication_events" >> /root/audit_email
        echo "======Failed Authentications======" >> /root/audit_email_attachment.txt
        $aureport --input-logs --start $start -au --failed 2>/dev/null >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt
        echo >> /root/audit_email_attachment.txt

fi

email="$(cat /root/audit_email)"

if ! [[ "$email" == "" ]]; then
	echo -e "======Audit Events Since $start======\n\n$email" | mail -s "Oncore Audit Event Alert" -r "root@FQDN"  -a /root/audit_email_attachment.txt <listserv email>
fi
