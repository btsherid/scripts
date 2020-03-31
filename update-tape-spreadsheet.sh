cp /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking.xlsx ~/projects
mv ~/Tape\ Usage\ Rate\ Tracking-updated.xlsx /tmp
sudo mv /tmp/Tape\ Usage\ Rate\ Tracking-updated.xlsx /datastore/alldata/netbackup/tapeStats/
sudo chmod 0644 /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking-updated.xlsx
sudo chgrp lbgadmins /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking-updated.xlsx
sudo mv /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking.xlsx /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking.xlsx.old
sudo mv /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking-updated.xlsx /datastore/alldata/netbackup/tapeStats/Tape\ Usage\ Rate\ Tracking.xlsx

