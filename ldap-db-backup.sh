#!/bin/sh
LDAPBK=ldap-$( date '+%Y%m%d' ).ldif
LDAPCONFIGBK=ldap-config-$( date '+%Y%m%d' ).ldif
BACKUPDIR=/datastore/serverdepot/ldap-db-backups
/usr/sbin/slapcat -v -b "dc=lbg,dc=unc,dc=edu" -l "$BACKUPDIR/$LDAPBK" 
/usr/sbin/slapcat -n 0 -l "$BACKUPDIR/$LDAPCONFIGBK"
#To restore run /usr/sbin/slapadd -l /datastore/serverdepot/ldap-db-backups/ldap-YYYYMMDD.ldif
