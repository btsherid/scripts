#!/bin/bash
tsm maintenance cleanup
tsm maintenance backup --file tableau-backup --append-date
rsync -avz /var/opt/tableau/tableau_server/data/tabsvc/files/backups/ /<<NFS storage>>/tableau_backups/
