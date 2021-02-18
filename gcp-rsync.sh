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
#excludes="-x ".*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai\|.*stdoe\|.*status\|.*working$""
excludes="-x ".*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai$""
server_excludes="-x ".*dev\|.*sys\|.*datastore\|.*dbstore\|.*home\|.*mnt\|.*proc\|.*run$""
#local_excludes="--exclude status --exclude stdoe --exclude working --exclude ~snapshot --exclude .snapshot --exclude *.bam --exclude *.bai" 
local_excludes="--exclude ~snapshot --exclude .snapshot --exclude *.bam --exclude *.bai" 
local_server_excludes="--exclude dev --exclude sys --exclude datastore --exclude dbstore --exclude webstore --exclude home --exclude mnt --exclude proc --exclude run"

while getopts ":p:ht:x:e:l" option; do
  case $option in
    p) input_path="$OPTARG";;
    h) echo "usage: $0 [-h (help)] [-p (/src/path)] [-x (gsutil exclude)] [-e (local rsync exclude)] [-t (timeout)] [-l (local)]"; 
       echo "-h: Print this help output"
       echo "-p: Path to rsync to GCP. Must end with a \"/\". Required."
       echo "-x: Configure additional excludes for gsutil rsync in addition to the default. Add excludes with python regex syntax. Example: -x .*<dir name>\|.*\.<file extension>"
       echo "-e: Configure additional exclude for local rsync in addition to the default. Add excludes with this rsync syntax. Example: -e \"--exclude <dir name> --exclude *.<file extension>\""
       echo "-t: Implement a timeout on the rsync command. Implemented by running \"timeout <timeout> <gsutil rsync command>\""
       echo "-l: "Run the rsync locally between the -p path and the fuse mounted bucket at /NS/lccc-gcp-archive."
    This is good for directories that fail network rsync, but the local rsync may take longer.
    For policies with excludes this is the preferred method because rsync handles excludes better than gsutil rsync."
       exit;;
    x) gcp_exclude_arg="$OPTARG";;
    e) local_exclude_arg="$OPTARG";;
    t) timeout="$OPTARG";;
    l) local=yes;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done

#If the user specified an additional exclude with the -x flag, include it.
if ! [[ "$gcp_exclude_arg" == "" ]]; then
	#excludes="-x "${gcp_exclude_arg}\|.*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai\|.*stdoe\|.*status\|.*working$""
	excludes="-x "${gcp_exclude_arg}\|.*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai$""
fi

#If the user specified an additional exclude with the -e flag, include it.
if ! [[ $local_exclude_arg == "" ]]; then
	local_excludes="--exclude status --exclude stdoe --exclude working --exclude ~snapshot --exclude .snapshot --exclude *.bam --exclude *.bai $local_exclude_arg"
fi

#Search for '@' in path. If there is an @, consider this a server backup.
input_path_server="$(echo $input_path | grep "@")"

#Get last character of input path. It needs to end with a '/' for the rsync command.
input_path_last_char="$(echo "${input_path: -1}")"

#Error handling
#If the input path is empty, exit because we don't know what to rsync.
if [[ "$input_path" == "" ]]; then
        echo "Error: Must specify input path with -p." >&2
        exit 1
#If the input path doesn't end in a '/', exit because the rsync won't work like we want it to.
elif ! [[ "$input_path_last_char" == '/' ]]; then
	echo "Error: Input path must end with a '/'"
	exit 1
#If -l flag not specified with server backup path, exit because gsutil rsync will fail with that input path.
elif ! [[ "$input_path_server" == "" ]]; then
	if [[ "$local" == "" ]]; then
		echo "Error: Cannot run server backup via gsutil. Please add -l"
		exit 1
	fi
#If -e flag is specified, but -l not specified, exit.
elif ! [[ "$local_exclude_arg" == "" ]]; then
	if [[ "$local" == "" ]]; then
		echo "Cannot add -e exclude without -l flag"
		exit 1
	fi
elif ! [[ "$gcp_exclude_arg" == "" ]]; then
	if [[ "$local" == "yes" ]]; then
		echo "Cannot specify -x with local rsync. Either use -e or eliminate -l"
		exit 1
	fi
fi

#If not a server backup, run the if clause, if a server backup run the else clause.
if [[ "$input_path_server" == "" ]]; then 

	#Transpose '/'s to '_'s in $input_path
	path_filename="$(echo "${input_path:1:${#input_path}-2}" | tr '/' '_')"

	#Get the last character of $path
	path_filename_last_char="$(echo "${path_filename: -1}")"


	#If the last character of the path_filename is a '*', remove it.
	if [[ "$path_filename_last_char" == "*" ]]; then
#		path="$(echo "${path_filename::-1}")"
		path="${path_filename//'*'}"
		rsync_dirs="$(ls -d $input_path)"
	elif [[ "$input_path" == *"snapshot"* ]]; then
		snapshot_folder="$(ls $input_path | grep "VLAN452\|weekly\|Windows" | grep "$today\|$today_weekly")"
		snapshot_path="$(echo $input_path | awk -F '.snapshot/' '{print $1}')"
		snapshot_path_filename="$(echo "${snapshot_path:1:${#snapshot_path}-2}" | tr '/' '_')"
	        path="${snapshot_path_filename}_.snapshot/${path_filename}_${snapshot_folder}"
	else
		path="$path_filename"
	fi
else
	#Get just the servername from the input path, stripping off the root@ and the ':'
	path="$(echo $input_path | awk -F '@' '{print $2}' | awk -F ':' '{print $1}')"
fi

#The filename is $path_filename with $date appended
if [[ "$input_path" == *"snapshot"* ]]; then
	filename="$date"
else
	filename="${path}_$date"
fi
/usr/bin/test ! -d $OUTPUTDIR/$path && mkdir -p $OUTPUTDIR/$path

#If local rsync check that the /NS/lccc-gcp-archive folder exists. If not, create it.
if [[ "$local" == "yes" ]]; then
	if [[ "$input_path_server" == "" ]]; then
		#For wildcard policies create /NS/lccc-gcp-archive folders for all wildcard folders
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
                        do
				/usr/bin/test ! -d $BUCKETDIR$entry && mkdir -p $BUCKETDIR$entry
			done
		#For non-wildcard policies create /NS/lccc-gcp-archive folder
		else
			/usr/bin/test ! -d $BUCKETDIR/$input_path && mkdir -p $BUCKETDIR/$input_path
		fi
	#For local server backups, created /NS/lccc-gcp-archive/server-backups folder
	else
		/usr/bin/test ! -d $BUCKETDIR/server-backups/$path && mkdir -p $BUCKETDIR/server-backups/$path
	fi
fi

#Write start time to log file
start_time="$(date)"
echo "Start time on $HOSTNAME" > $OUTPUTDIR/$path/$filename
date >> $OUTPUTDIR/$path/$filename
echo >> $OUTPUTDIR/$path/$filename

#Start timer for rsync
SECONDS=0

if [[ "$local" == "yes" ]]; then
	#Run rsync to GCP fuse mounted bucket
	if [[ "$timeout" == "" ]]; then
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
			do
				echo "Running rsync -avz --progress --no-links $local_excludes $entry $BUCKETDIR$entry" &>> $OUTPUTDIR/$path/$filename
				rsync -avz --progress --no-links $local_excludes $entry $BUCKETDIR$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
					break
				fi		
			done
		elif [[ "$input_path" == *"snapshot"* ]]; then
			echo "Running rsync -avz --progress --no-links $local_excludes ${input_path}${snapshot_folder} $BUCKETDIR${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
                        rsync -avz --progress --no-links $local_excludes ${input_path}${snapshot_folder} $BUCKETDIR${input_path}${snapshot_folder}  &>> $OUTPUTDIR/$path/$filename
                        status=$?
		else
			#If not a server backup run if statements. If a server backup run else statements.
			if [[ "$input_path_server" == "" ]]; then
				echo "Running rsync -avz --progress --no-links $local_excludes $input_path /NS/lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
				rsync -avz --progress --no-links $local_excludes $input_path $BUCKETDIR$input_path &>> $OUTPUTDIR/$path/$filename
				status=$?
			else
				echo "Running rsync -avz --progress --no-links $local_server_excludes $input_path $BUCKETDIR/server-backups/$path" &>> $OUTPUTDIR/$path/$filename
				rsync -avz --progress --no-links $local_server_excludes $input_path $BUCKETDIR/server-backups/$path &>> $OUTPUTDIR/$path/$filename
				status=$?
			fi
		
		fi	
	#If timeout argument given, run rsync to GCP fuse mounted bucket with timeout
	else
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
                        do
				echo "Running timeout $timeout rsync -avz --progress --no-links $local_excludes $entry /NS/lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout rsync -avz --progress --no-links $local_excludes $entry $BUCKETDIR$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
					break
                                fi
			done
                elif [[ "$input_path" == *"snapshot"* ]]; then
                        echo "Running timeout $timeout rsync -avz --progress --no-links $local_excludes ${input_path}${snapshot_folder} $BUCKETDIR${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
                        timeout $timeout rsync -avz --progress --no-links $local_excludes ${input_path}${snapshot_folder} $BUCKETDIR${input_path}${snapshot_folder}  &>> $OUTPUTDIR/$path/$filename
                        status=$?

		else
			#If not a server backup run if statements. If a server backup run else statements.
			if [[ "$input_path_server" == "" ]]; then
				echo "Running timeout $timeout rsync -avz --progress --no-links $local_excludes $input_path /NS/lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout rsync -avz --progress --no-links $local_excludes $input_path $BUCKETDIR$input_path &>> $OUTPUTDIR/$path/$filename
				status=$?
			else
				echo "Running timeout $timeout rsync -avz --progress --no-links $local_server_excludes $input_path $BUCKETDIR/server-backups/$path" &>> $OUTPUTDIR/$path/$filename
                                timeout $timeout rsync -avz --progress --no-links $local_server_excludes $input_path $BUCKETDIR/server-backups/$path &>> $OUTPUTDIR/$path/$filename
                                status=$?
			fi
		fi	
	fi	
else
	#Run rsync to GCP
       if [[ "$timeout" == "" ]]; then
		if [[ "$path_filename_last_char" == "*" ]]; then
                        for entry in $rsync_dirs
                        do
				echo "Running gsutil -m rsync -r -e -C "$excludes" $entry gs://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				gsutil -m rsync -r -e -C "$excludes" $entry gs://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
                                        break
                                fi
			done
                elif [[ "$input_path" == *"snapshot"* ]]; then
                        echo "Running gsutil -m rsync -r -e -C "$excludes" ${input_path}${snapshot_folder} gs://lccc-gcp-archive${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
                        gsutil -m rsync -r -e -C "$excludes" ${input_path}${snapshot_folder} gs://lccc-gcp-archive${input_path}${snapshot_folder} &>> $OUTPUTDIR/$path/$filename
                        status=$?
		else
			echo "Running gsutil -m rsync -r -e -d -C "$excludes" $input_path gs://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
        		gsutil -m rsync -r -e -d -C "$excludes" $input_path gs://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
			status=$?
		fi
        #If timeout argument given, run rsync to GCP with timeout
        else
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
        	        do
				echo "Running timeout $timeout gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				status=$?
				if ! [[ $status == "0" ]]; then
                                        break
                                fi
			done
		elif [[ "$input_path" == *"snapshot"* ]]; then
                	echo "Running timeout $timeout gsutil -m rsync -r -e -C "$excludes" ${input_path}${snapshot_folder} gs://lccc-gcp-archive${input_path}${snapshot_folder}" &>> $OUTPUTDIR/$path/$filename
	               	timeout $timeout gsutil -m rsync -r -e -C "$excludes" ${input_path}${snapshot_folder} gs://lccc-gcp-archive${input_path}${snapshot_folder} &>> $OUTPUTDIR/$path/$filename
                	status=$?
		else
			echo "Running timeout $timeout gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
        		timeout $timeout gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
			status=$?
		fi
        fi

fi


#Stop timer for rsync
duration=$SECONDS

#If rsync timed out send email notification
if [[ "$status" == "124" ]]; then
	echo -e "GCP rsync for $input_path started $start_time on $HOSTNAME timed out. Timeout value was $timeout.\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync timed out" brendan.sheridan@unc.edu	
#If rsync had an error send email notification
elif ! [[ "$status" == "0" ]]; then
	echo -e "GCP rsync for $input_path started $start_time on $HOSTNAME exited with return code $status\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync error" brendan.sheridan@unc.edu
else
	echo -e "GCP rsync for $input_path started $start_time on $HOSTNAME finished successfully in $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync completion" brendan.sheridan@unc.edu
fi
 

#Write end time to log file
echo >> $OUTPUTDIR/$path/$filename
echo "End time" >> $OUTPUTDIR/$path/$filename
date >> $OUTPUTDIR/$path/$filename
echo >> $OUTPUTDIR/$path/$filename

#Print out elapsed rsync time based on SECONDS
echo "rsync ran for $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds." >> $OUTPUTDIR/$path/$filename
