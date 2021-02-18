#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

#export TMPDIR=""
timeout=""
date="$(date +%Y-%m-%d-%H%M%S)"
today="$(date +%m-%d-%Y)"
today_weekly="$(date +%Y-%m-%d)"
OUTPUTDIR="/datastore/serverdepot/netbackup/gcp-rsync-logs"
BUCKETDIR="/NS/lccc-gcp-archive"
#excludes="--exclude *.bam --exclude *.bai --exclude daily.** --exclude hourly.** --exclude weekly.**"
excludes="--exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/**"
server_excludes="--exclude dev/** --exclude sys/** --exclude datastore/** --exclude dbstore/** --exclude webstore/** --exclude logstore/** --exclude home/** --exclude mnt/** --exclude proc/** --exclude run/** --exclude NS/** --exclude libvirt/images/** --exclude mkhomes/** --exclude soldata_new/** --exclude system/** --exclude tsol/**"

while getopts ":p:ht:e:" option; do
  case $option in
    p) input_path="$OPTARG";;
    h) echo "usage: $0 [-h (help)] [-p (/src/path)] [-e (exclude)] [-t (timeout)]]"; 
       echo "-h: Print this help output"
       echo "-p: Path to rclone copy to GCP. Must end with a \"/\". Required."
       echo "-e: Configure additional exclude in addition to the default. Add excludes with this syntax. Example: -e \"--exclude <dir name> --exclude *.<file extension>\""
       echo "-t: Implement a timeout on the rclone command. Implemented by running \"timeout <timeout> <rclone command>\""
       exit;;
    e) exclude_arg="$OPTARG";;
    t) timeout="$OPTARG";;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done


#If the user specified an additional exclude with the -e flag, include it.
if ! [[ $exclude_arg == "" ]]; then
	excludes="--exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/** $exclude_arg"
fi

#Get last character of input path. It needs to end with a '/' for the rclone command.
input_path_last_char="$(echo "${input_path: -1}")"

#Error handling
#If the input path is empty, exit because we don't know what to rclone.
if [[ "$input_path" == "" ]]; then
        echo "Error: Must specify input path with -p. Run gcp-rclone.sh -h for usage." >&2
        exit 1
#If the input path doesn't end in a '/', exit because the rclone won't work like we want it to.
elif ! [[ "$input_path_last_char" == '/' ]]; then
	echo "Error: Input path must end with a '/'. Run gcp-rclone.sh -h for usage."
	exit 1
fi
#Transpose '/'s to '_'s in $input_path
if [[ "$input_path" == *".bioinf"* ]] || [[ "$input_path" == *".med"* ]] || [[ "$input_path" == *".local"* ]]; then
	path_filename="$(echo "$input_path" | tr -d '/')"
	rclone_remote="$(echo "$input_path" | awk -F '.' '{print $1}')"
else
	path_filename="$(echo "${input_path:1:${#input_path}-2}" | tr '/' '_')"
fi

#Get the last character of $path
path_filename_last_char="$(echo "${path_filename: -1}")"

#If the last character of the path_filename is a '*', remove it.
if [[ "$path_filename_last_char" == "*" ]]; then
	path="${path_filename//'*'}"
	if [[ "$input_path" == "/datastore/nextgenout5/share/labs/bioinformatics/seqware/h*/" ]]; then
		rsync_dirs="$(ls -d $input_path | grep -v "\/hu\|hollern")"
	else
		rsync_dirs="$(ls -d $input_path)"
	fi
elif [[ "$input_path" == *"snapshot"* ]]; then
        snapshot_folder="$(ls $input_path | grep "VLAN452\|weekly\|Windows" | grep "$today\|$today_weekly")"
        snapshot_path="$(echo $input_path | awk -F '.snapshot/' '{print $1}')"
	snapshot_path_filename="$(echo "${snapshot_path:1:${#snapshot_path}-2}" | tr '/' '_')"
        path="${snapshot_path_filename}_.snapshot/${path_filename}_${snapshot_folder}"
else
    path="$path_filename"
fi


#The filename is $path_filename with $date appended
if [[ "$input_path" == *"snapshot"* ]]; then
        filename="$date"
else
	filename="${path}_$date"
fi
/usr/bin/test ! -d $OUTPUTDIR/$path && mkdir $OUTPUTDIR/$path




#Write start time to log file
start_time="$(date)"
echo "Start time on $HOSTNAME" > $OUTPUTDIR/$path/$filename
date >> $OUTPUTDIR/$path/$filename
echo >> $OUTPUTDIR/$path/$filename

#Start timer for rclone
SECONDS=0

	#Run rclone to GCP
       if [[ "$timeout" == "" ]]; then
		if [[ "$path_filename_last_char" == "*" ]]; then
                        for entry in $rsync_dirs
                        do
				echo "Running rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $entry lbg-gcp://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $entry lbg-gcp://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
                                        break
                                fi
			done
		elif [[ "$input_path" == *".bioinf"* ]] || [[ "$input_path" == *".med"* ]] || [[ "$input_path" == *".local"* ]]; then
			echo "Running rclone copy --ignore-checksum --ignore-size --progress --sftp-skip-links --skip-links $server_excludes $rclone_remote:/ lbg-gcp://lccc-gcp-archive/server-backups/$input_path" &>> $OUTPUTDIR/$path/$filename
	        rclone copy --ignore-checksum --ignore-size --progress --skip-links --sftp-skip-links $server_excludes $rclone_remote:/ lbg-gcp://lccc-gcp-archive/server-backups/$input_path &>> $OUTPUTDIR/$path/$filename
            status=$?
		elif [[ "$input_path" == *"snapshot"* ]]; then
                        echo "Running rclone copy --local-no-check-updated --progress --skip-links $excludes ${input_path}${snapshot_folder} lbg-gcp://lccc-gcp-archive${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
                        rclone copy --local-no-check-updated --progress --skip-links $excludes ${input_path}${snapshot_folder} lbg-gcp://lccc-gcp-archive${input_path}${snapshot_folder}  &>> $OUTPUTDIR/$path/$filename
                        status=$?
		else
				echo "Running rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $input_path lbg-gcp://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
        			rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $input_path lbg-gcp://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
				status=$?
			
		fi
        #If timeout argument given, run rsync to GCP with timeout
        else
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
        	        do
				echo "Running timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $entry lbg-gcp://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $entry lbg-gcp://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
                                        break
                                fi
			done
		elif [[ "$input_path" == *".bioinf"* ]] || [[ "$input_path" == *".med"* ]] || [[ "$input_path" == *".local"* ]]; then
	                echo "Running timeout $timeout rclone copy --ignore-checksum --ignore-size --progress --sftp-skip-links --skip-links $server_excludes $rclone_remote:/ lbg-gcp://lccc-gcp-archive/server-backups/$input_path" &>> $OUTPUTDIR/$path/$filename
    	            timeout $timeout rclone copy --ignore-checksum --ignore-size --progress --sftp-skip-links --skip-links $server_excludes $rclone_remote:/ lbg-gcp://lccc-gcp-archive/server-backups/$input_path &>> $OUTPUTDIR/$path/$filename
        	        status=$?
                elif [[ "$input_path" == *"snapshot"* ]]; then
                        echo "Running timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes ${input_path}${snapshot_folder} lbg-gcp://lccc-gcp-archive${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
                        timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes ${input_path}${snapshot_folder} lbg-gcp://lccc-gcp-archive${input_path}${snapshot_folder}  &>> $OUTPUTDIR/$path/$filename
                        status=$?
		else
				echo "Running timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $input_path lbg-gcp://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
	        		timeout $timeout rclone copy --local-no-check-updated --ignore-size --progress --skip-links $excludes $input_path lbg-gcp://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
				status=$?
		fi
        fi


#Stop timer for rclone
duration=$SECONDS

#If rclone timed out send email notification
if [[ "$status" == "124" ]]; then
	echo -e "GCP rclone copy for $input_path started $start_time on $HOSTNAME timed out. Timeout value was $timeout.\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rclone timed out" brendan.sheridan@unc.edu	
#If rclone had an error send email notification
elif ! [[ "$status" == "0" ]]; then
	echo -e "GCP rclone copy for $input_path started $start_time on $HOSTNAME exited with return code $status\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rclone error" brendan.sheridan@unc.edu
else
	echo -e "GCP rclone copy for $input_path started $start_time on $HOSTNAME finished successfully in $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rclone completion" brendan.sheridan@unc.edu
fi
 

#Write end time to log file
echo >> $OUTPUTDIR/$path/$filename
echo "End time" >> $OUTPUTDIR/$path/$filename
date >> $OUTPUTDIR/$path/$filename
echo >> $OUTPUTDIR/$path/$filename

#Print out elapsed rclone time based on SECONDS
echo "rclone copy ran for $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds." >> $OUTPUTDIR/$path/$filename
