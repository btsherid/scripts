#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

export TMPDIR=/tmp
timeout=""
date="$(date +%Y%m%d%H%M%S)"
OUTPUTDIR="/datastore/serverdepot/netbackup/gcp-rsync-logs"
BUCKETDIR="/NS/lccc-gcp-archive"
#excludes="-x \".*\.snapshot$|.*\~snapshot$|.*\.bam$|.*\.bai$|.*stdoe\/.*$|.*status\/.*$|.*working\/.*$}\""
excludes="-x ".*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai\|.*stdoe\|.*status\|.*working$""
local_excludes="--exclude status --exclude stdoe --exclude working --exclude ~snapshot --exclude .snapshot --exclude *.bam --exclude *.bai" 

while getopts ":p:ht:x:e:l" option; do
  case $option in
    p) input_path="$OPTARG";;
    h) echo "usage: $0 [-h (help)] [-p (/src/path)] [-x (gsutil exclude)] [-e (local rsync exclude)] [-t (timeout)] [-l (local)]"; 
       echo "-h: Print this help output"
       echo "-p: Path to rsync to GCP. Required."
       echo "-x: Configure additional excludes for gsutil rsync in addition to the default. Add excludes with python regex syntax. Example: -e .*<dir name>\|.*\.<file extension>"
       echo "-e: Configure additional exclude for local rsync in addition to the default. Add excludes with this rsync syntax. Example: -x -e \"--exclude <dir name> --exclude *.<file extension>\""
       echo "-t: Implement a timeout on the rsync command. Implemented by running \"timeout <timeout> <gsutil rsync command>\""
       echo "-l: "Run the rsync locally between the -p path and the fuse mounted bucket at /NS/lccc-gcp-archive."
    This is good for directories with long file names that fail network rsync, but the local rsync may take longer" 
#    because the rsync will have to iterate over all files every time. Network rsync to GCP is much better in terms of caching.
#    For example, for a rsync of a 1TB directory with no changes, network rsync took 14 seconds. Local rsync took 31 hours."
       exit;;
    x) gcp_exclude_arg="$OPTARG";;
    e) local_exclude_arg="$OPTARG";;
    t) timeout="$OPTARG";;
    l) local=yes;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done

#If the user specified an additional exclude with the -x flag, include it.
if ! [[ $gcp_exclude_arg == "" ]]; then
	excludes="-x ".*\.snapshot\|.*snapshot\|.*\.bam\|.*\.bai\|.*stdoe\|.*status\|.*working\|$gcp_exclude_arg$""
fi

#If the user specified an additional exclude with the -e flag, include it.
if ! [[ $local_exclude_arg == "" ]]; then
	local_excludes="--exclude status --exclude stdoe --exclude working --exclude ~snapshot --exclude .snapshot --exclude *.bam --exclude *.bai $local_exclude_arg"
fi

#Get last character of input path. It needs to end with a '/' for the rsync command.
input_path_last_char="$(echo "${input_path: -1}")"

#If the input path is empty, exit because we don't know what to rsync.
if [[ "$input_path" == "" ]]; then
        echo "Error: Must specify input path with -p." >&2
        exit 1
#If the input path doesn't end in a '/', exit because the rsync won't work like we want it to.
elif ! [[ "$input_path_last_char" == '/' ]]; then
	echo "Error: Input path must end with a '/'"
	exit 1
fi

#Transpose '/'s to '_'s in $input_path
#path_filename="$(echo "$input_path" | tr '/' '_' )"
path_filename="$(echo "${input_path:1:${#input_path}-2}" | tr '/' '_')"

#Get the last character of $path
path_filename_last_char="$(echo "${path_filename: -1}")"


#If the last character of the path_filename is a '*', remove it.
if [[ "$path_filename_last_char" == "*" ]]; then
        path="$(echo "${path_filename::-1}")"
	rsync_dirs="$(ls -d $input_path)"
else
	path="$path_filename"
fi

#The filename is $path_filename with $date appended
filename="${path}_$date"

/usr/bin/test ! -d $OUTPUTDIR/$path && mkdir $OUTPUTDIR/$path

#If local rsync check that the /NS/lccc-gcp-archive folder exists. If not, create it.
if [[ "$local" == "yes" ]]; then
	/usr/bin/test ! -d $BUCKETDIR/$input_path && mkdir -p $BUCKETDIR/$input_path
fi


#Write start time to log file
start_time="$(date)"
echo "Start time" > $OUTPUTDIR/$path/$filename
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
				echo "Running rsync -avz $local_excludes $entry /NS/lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				rsync -avz $local_excludes $entry /NS/lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				if ! [[ $? == "0" ]]; then 
					break
				fi		
			done
		else
			echo "Running rsync -avz $local_excludes $input_path /NS/lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
			rsync -avz $local_excludes $input_path /NS/lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
		fi
	#If timeout argument given, run rsync to GCP fuse mounted bucket with timeout
	else
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
                        do
				echo "Running timeout $timeout rsync -avz $local_excludes $entry /NS/lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout rsync -avz $local_excludes $entry /NS/lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				if ! [[ $? == "0" ]]; then
                                        break
                                fi
			done
		else
			echo "Running timeout $timeout rsync -avz $local_excludes $input_path /NS/lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
			timeout $timeout rsync -avz $local_excludes $input_path /NS/lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
		fi
	fi
else
	#Run rsync to GCP
       if [[ "$timeout" == "" ]]; then
		if [[ "$path_filename_last_char" == "*" ]]; then
                        for entry in $rsync_dirs
                        do
				echo "Running gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				if ! [[ $? == "0" ]]; then
                                        break
                                fi
			done
		else
			echo "Running gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
        	        gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
		fi
        #If timeout argument given, run rsync to GCP with timeout
        else
		if [[ "$path_filename_last_char" == "*" ]]; then
			for entry in $rsync_dirs
        	        do
				echo "Running timeout $timeout gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry" &>> $OUTPUTDIR/$path/$filename
				timeout $timeout gsutil -m rsync -r -e -C $excludes $entry gs://lccc-gcp-archive$entry &>> $OUTPUTDIR/$path/$filename
				if ! [[ $? == "0" ]]; then
                                        break
                                fi
			done
		else
			echo "Running timeout $timeout gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path" &>> $OUTPUTDIR/$path/$filename
        	        timeout $timeout gsutil -m rsync -r -e -C $excludes $input_path gs://lccc-gcp-archive$input_path &>> $OUTPUTDIR/$path/$filename
		fi
        fi

fi

status=$?

#Stop timer for rsync
duration=$SECONDS

#If rsync timed out send email notification
if [[ "$status" == "124" ]]; then
	echo -e "GCP rsync for $input_path started $start_time timed out. Timeout value was $timeout.\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync timed out" brendan.sheridan@unc.edu	
#If rsync had an error send email notification
elif ! [[ "$status" == "0" ]]; then
	echo -e "GCP rsync for $input_path started $start_time exited with return code $status\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync error" brendan.sheridan@unc.edu
else
	echo -e "GCP rsync for $input_path started $start_time finished successfully in $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds\n\nLog file is located at $OUTPUTDIR/$path/$filename" | mail -s "GCP Rsync completion" brendan.sheridan@unc.edu
fi
 

#Write end time to log file
echo >> $OUTPUTDIR/$path/$filename
echo "End time" >> $OUTPUTDIR/$path/$filename
date >> $OUTPUTDIR/$path/$filename
echo >> $OUTPUTDIR/$path/$filename

#Print out elapsed rsync time based on SECONDS
echo "rsync ran for $(($duration / 60 / 60)) hours $(($duration / 60 %60)) minutes and $(($duration % 60)) seconds." >> $OUTPUTDIR/$path/$filename

