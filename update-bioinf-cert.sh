#!/bin/bash
year=$(date +"%Y")
new_key_file="/datastore/serverdepot/certs/any.<redacted>-${year}.key"
new_cert_file="/datastore/serverdepot/certs/any.<redacted>_cert-${year}.cer"
new_interm_file="/datastore/serverdepot/certs/any.<redacted>_interm-${year}.cer"
key_file="$((sudo ls -la /etc/pki/tls/private/any.<redacted>-*.key | grep "cannot access") 2>&1)"
cert_file="$((sudo ls -la /etc/pki/tls/certs/any.<redacted>_cert-*.cer | grep "cannot access") 2>&1)"
interm_file="$((sudo ls -la /etc/pki/tls/certs/any.<redacted>_interm-*.cer | grep "cannot access") 2>&1)"


if [ ! -z "$key_file" ]; then
	echo "ERROR: Key file does not follow naming convention."
	echo "Key file should be named any.<redacted>-XXXX.key, where XXXX is the current year."
	exit 1
fi

if [ ! -z "$cert_file" ]; then
        echo "ERROR: Certificate file does not follow naming convention."
        echo "Certificate file should be named any.<redacted>_cert-XXXX.cer, where XXXX is the current year."
	exit 1
fi

if [ ! -z "$interm_file" ]; then
        echo "ERROR: Intermediate certificate file does not follow naming convention."
        echo "Intermediate certificate file should be named any.<redacted>_interm-XXXX.cer, where XXXX is the current year."
        exit 1
fi

#Test if new key file exists with desired name
if [ ! -f "$new_key_file" ]; then
	echo "ERROR: New key file does not exist at /datastore/serverdepot/certs/any.<redacted>-${year}.key"
	exit 1
fi

#Test if new certificate file exists with desired name
if [ ! -f "$new_cert_file" ]; then 
	echo "ERROR: New certificate file does not exist at /datastore/serverdepot/certs/any.<redacted>_cert-${year}.cer"
	exit 1
fi


#Test if new intermediate certificate file exists with desired name
if [ ! -f "$new_interm_file" ]; then
        echo "ERROR: New intermediate certificate file does not exist at /datastore/serverdepot/certs/any.<redacted>_interm-${year}.cer"
	exit 1
fi


cert_sym_link_name="$(sudo ls -la /etc/pki/tls/certs/ | grep -E -- '-> any' | grep bioinf | grep -E -- "-2" | grep cert | awk '{print $9}')"
interm_sym_link_name="$(sudo ls -la /etc/pki/tls/certs/ | grep -E -- '-> any' | grep bioinf | grep -E -- "-2" | grep interm | awk '{print $9}')"
key_sym_link_name="$(sudo ls -la /etc/pki/tls/private/ | grep -E -- '-> any' | grep bioinf | grep -E -- "-2" | awk '{print $9}' )"

cert_sym_link_count="$(echo $cert_sym_link_name | tr ' ' '\n' | wc -l)"
interm_sym_link_count="$(echo $interm_sym_link_name | tr ' ' '\n' | wc -l)"
key_sym_link_count="$(echo $key_sym_link_name | tr ' ' '\n' | wc -l)"

if [ ! $cert_sym_link_count -eq 1 ]; then
	echo "ERROR:"
	echo "More than one certificate symlink in /etc/pki/tls/certs points to the bioinf certificate"
	echo "Only the bioinf certificate symlink should point to the bioinf certificate"
	echo "Please change the other certificate symlinks to point to the bioinf certicate symlink insted of the bioinf certificate. Below shows how the setup should look."
	echo
	echo "          ============/etc/pki/tls/certs============"
	echo "          bioinf_cert_symlink   -> bioinf_cert_file"
	echo "          other_cert_symlink    -> bioinf_cert_symlink"
	echo

	exit 1
fi

if [ ! $interm_sym_link_count -eq 1 ]; then
	echo "ERROR:"
        echo "More than one intermediate certficate symlink in /etc/pki/tls/certs points to the bioinf intermediate certificate"
        echo "Only the bioinf intermediate certificate symlink should point to the bioinf intermediate certificate"
        echo "Please change the other intermedite certificate symlinks to point to the bioinf intermediate certicate symlink insted of the bioinf certificate. Below shows how the setup should look."
	echo
	echo "          ============/etc/pki/tls/certs============"
	echo "          bioinf_interm_symlink -> bioinf_interm_file"
	echo "          other_interm_symlink  -> bioinf_interm_symlink"
	echo
        exit 1
fi

if [ ! $key_sym_link_count -eq 1 ]; then
	echo "ERROR:"
        echo "More than one key symlink in /etc/pki/tls/private points to the bioinf key"
        echo "Only the bioinf key symlink should point to the bioinf key"
        echo "Please change the other key symlinks to point to the bioinf key symlink insted of the bioinf certificate. Below shows how the setup should look."
	echo
	echo "          ============/etc/pki/tls/private============"
	echo "          bioinf_key_symlink    -> bioinf_key_file"
	echo "          other_key_symlink     -> bioinf_key_symlink"
	echo

        exit 1
fi

sudo cp /datastore/serverdepot/certs/any.<redacted>-${year}.key /etc/pki/tls/private
sudo rm /etc/pki/tls/private/${key_sym_link_name} 
cd /etc/pki/tls/private
sudo ln -s any.<redacted>-${year}.key $key_sym_link_name

sudo cp /datastore/serverdepot/certs/any.<redacted>_* /etc/pki/tls/certs
sudo rm /etc/pki/tls/certs/${cert_sym_link_name}
sudo rm /etc/pki/tls/certs/${interm_sym_link_name}
cd /etc/pki/tls/certs
sudo ln -s any.<redacted>_cert-${year}.cer $cert_sym_link_name
sudo ln -s any.<redacted>_interm-${year}.cer $interm_sym_link_name

apache_status="$((sudo apachectl -S | head -n1 | awk '{$1=$1};1') 2>&1)"

if [ "$apache_status" == "VirtualHost configuration:" ]; then
	sudo apachectl graceful	
	echo "Bioinf wild card certificate updated"
else
	echo "Possible Apache error." 
	echo "New cert and key files are in place. Sym links have been created."
	echo "Please investigate Apache (apachectl -S) and restart (sudo apachectl graceful) to finish updating Bioinf wild card certificate"
fi
