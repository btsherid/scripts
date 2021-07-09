#!/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi


#These are the volumes we want to search
volumes="alldata clustersysshare home1 home2 home3 home4 mapseq-analysis nextgenout2 nextgenout3 nextgenout4 nextgenout5 peroulab seqdata seqdata_hosp seqware-analysis"
out_file="/tmp/fastq_fq.uncompressed"

#Delete the content of the output files in case they already exist
truncate -s 0 $out_file
truncate -s 0 ${out_file}_working_canbedeleted
truncate -s 0 ${out_file}_with_gz

echo "*****Searching for fastq and fq files*****"
for entry in $volumes
do
echo "Searching $entry"
sf query $entry: -d , -h --ext fastq --ext fq  --size 10M-1000000T --format "vol_path username uid groupname size ct" >> $out_file
done

echo
echo "*****Changing starfish output format to file paths*****"
sed -i 's/alldata:/\/datastore\/alldata\//g' $out_file
sed -i 's/clustersysshare:/\/datastore\/clustersysshare\//g' $out_file
sed -i 's/home1:/\/home\//g' $out_file
sed -i 's/home2:/\/home\//g' $out_file
sed -i 's/home3:/\/home\//g' $out_file
sed -i 's/home4:/\/home\//g' $out_file
sed -i 's/mapseq-analysis:/\/datastore\/rclbg\/mapseq-analysis\//g' $out_file
sed -i 's/nextgenout2:/\/datastore\/nextgenout2\//g' $out_file
sed -i 's/nextgenout3:/\/datastore\/nextgenout3\//g' $out_file
sed -i 's/nextgenout4:/\/datastore\/nextgenout4\//g' $out_file
sed -i 's/nextgenout5:/\/datastore\/nextgenout5\//g' $out_file
sed -i 's/peroulab:/\/datastore\/labnproject\/peroulab\//g' $out_file
sed -i 's/seqdata:/\/datastore\/labnproject\/seqdata\//g' $out_file
sed -i 's/seqdata_hosp:/\/datastore\/seqdata_hosp\//g' $out_file
sed -i 's/seqware-analysis:/\/datastore\/labnproject\/seqware-analysis\//g' $out_file

echo
echo "*****Removing unneeded lines*****"
sed -i '/vol_path/d' $out_file

echo
echo "*****Sorting uniquely by size*****"
sort -u -t, -k5 -n $out_file > ${out_file}.sorted
mv ${out_file}.sorted $out_file

echo
echo "*****Testing file paths to make sure files exist*****"
total="$(wc -l $out_file | awk '{print $1}')"
COUNTER=1
while read -r line
do
	#Files that exist will get saved to a file. If ls finds nothing, the error goes to /dev/null
	echo "$line" | awk -F ',' '{print $1}' | xargs -I '{}' ls -lah "{}" 2>> ${out_file}.exists 1>/dev/null
	#Display a rolling counter
	if (($COUNTER  < $total))
        then
                echo "$COUNTER/$total";printf "\033[A"
                COUNTER=$((COUNTER+1))

        #For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
        else
               echo "$COUNTER/$total"
               echo
               COUNTER=$(($COUNTER+1))
        fi

done < $out_file
if test -f "${out_file}.exists"; then
	echo
	echo "*****Removing files that don't exist from output file*****"
	total="$(wc -l ${out_file}.exists | awk '{print $1}')"
	COUNTER=1
	while read -r line;
	do	
		#Get line number of file that doesn't exist
		line_number="$(echo "$line" | awk -F 'access ' '{print $2}' | awk -F ':' '{print $1}' | xargs -I '{}' grep -n {} $out_file | awk -F ':' '{print $1}')"
		#Delete that line number from $out_file
		sed -i "${line_number}d" $out_file 2>/dev/null

	        if (($COUNTER  < $total))
	        then
        	        echo "$COUNTER/$total";printf "\033[A"
                	COUNTER=$((COUNTER+1))
	
        	#For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
	        else
        	       echo "$COUNTER/$total"
	               echo
        	       COUNTER=$(($COUNTER+1))
	        fi
	
	done < ${out_file}.exists
	#Remove empty lines from $out_file
	sed '/^$/d' -i $out_file
	rm ${out_file}.exists 

	echo
	echo "*****Extracting fastq and fq files in working directories to a different file*****"
	grep "/working/\|/work/\|/nextflow-work/" $out_file > ${out_file}_working_total

	grep -v "/working/\|/work/\|/nextflow-work/" $out_file > ${out_file}.1
	mv ${out_file}.1 ${out_file}

	echo
	echo "*****Finding fastq and fq files with a corresponding gz file*****"
	total="$(wc -l $out_file | awk '{print $1}')"
	COUNTER=1
	while read -r line;
	do
		filepath="$(echo $line | awk -F ',' '{print $1}')"
		
		if test -f "${filepath}.gz"; then
	        	echo $line >> ${out_file}_with_gz
		fi
		#Display a rolling counter
		if (($COUNTER  < $total))
        	then
	                echo "$COUNTER/$total";printf "\033[A"
	                COUNTER=$((COUNTER+1))

        	#For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
	        else
        	       echo "$COUNTER/$total"
	               echo
        	       COUNTER=$(($COUNTER+1))
	        fi
	done < $out_file

	#Remove files in ${out_file}_with_gz from $out_file
	while read -r line;
	do
		#Get line number of file that doesn't exist
		line_number="$(grep -n $line $out_file | awk -F ':' '{print $1}')"
		#Delete that line number from $out_file
		sed -i "${line_number}d" $out_file
	done < ${out_file}_with_gz
	#Remove empty lines from $out_file
	sed '/^$/d' -i $out_file

	echo
	echo "*****Checking for files in working dirs that can be deleted*****"
	total="$(wc -l ${out_file}_working_total | awk '{print $1}')"
	COUNTER=1
	while read -r line;
	do
		six_months_ago="$(date +%s --date='-6 months')"
		three_months_ago="$(date +%s --date='-3 months')"
		filename_delete="$(echo $line | awk -F ',' '{print $1}' | awk -F '/' '{print $NF}' | grep "temp\|unaligned")"
		ctime="$(echo $line | awk -F ',' '{print $NF}')"
	
		#If file is in working directory and older than 6 months it can be deleted
		if (($ctime < $six_months_ago ))
		then
			echo $line >> ${out_file}_working_old
		#If file is in working directory and older than 3 months with name temp*.fastq, temp*.fq, unaligned*.fastq, or unaligned*.fq, it can be deleted
		elif (($ctime < $three_months_ago))
		then
			if ! [[ "$filename_delete" == "" ]]; then
				echo $line >> ${out_file}_working_old
			fi
		fi

		#Display a rolling counter
		if (($COUNTER  < $total))
        	then
                	echo "$COUNTER/$total";printf "\033[A"
                	COUNTER=$((COUNTER+1))

	        #For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
        	else
	               echo "$COUNTER/$total"
        	       echo
	               COUNTER=$(($COUNTER+1))
        	fi

	done < ${out_file}_working_total

	rm ${out_file}_working_total
	if test -f "${out_file}_working_old"; then
		mv ${out_file}_working_old ${out_file}_working_canbedeleted
	else
		touch ${out_file}_working_canbedeleted
	fi

	echo
	echo "*****Converting timestamps to human readable dates for files outside working dirs*****"
	total="$(wc -l $out_file | awk '{print $1}')"
	COUNTER=1
	while read -r line;
	do
		ctime="$(echo $line | awk -F ',' '{print $NF}')"
		ctime_converted="$(date -d @$ctime)"
		line_clipped="$(echo $line | awk 'BEGIN {FS=",";OFS=",";} {$NF=""; print $0}')"
		echo ${line_clipped}$ctime_converted >> ${out_file}_converted
		if (($COUNTER  < $total))
	        then
	               	echo "$COUNTER/$total";printf "\033[A"
	               	COUNTER=$((COUNTER+1))

	        #For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
	        else
	                echo "$COUNTER/$total"
			echo
			COUNTER=$(($COUNTER+1))
        	fi

	done < $out_file
	rm $out_file
	mv ${out_file}_converted $out_file

	echo
	echo "*****Converting timestamps to human readable dates for files inside working dirs*****"
	total="$(wc -l ${out_file}_working_canbedeleted | awk '{print $1}')"
	COUNTER=1
	while read -r line;
	do
		ctime="$(echo $line | awk -F ',' '{print $NF}')"
		ctime_converted="$(date -d @$ctime)"
		line_clipped="$(echo $line | awk 'BEGIN {FS=",";OFS=",";} {$NF=""; print $0}')"
		echo ${line_clipped}$ctime_converted >> ${out_file}_working_canbedeleted_converted
		if (($COUNTER  < $total))
	        then
	                echo "$COUNTER/$total";printf "\033[A"
	                COUNTER=$((COUNTER+1))
	        #For the last line we want to  increment the counter and display a final message but we don't want to clear the line.
	        else
	                echo "$COUNTER/$total"
	                echo
	                COUNTER=$(($COUNTER+1))
	        fi

	done < ${out_file}_working_canbedeleted
	rm ${out_file}_working_canbedeleted
	if test -f "${out_file}_working_canbedeleted_converted"; then
		mv ${out_file}_working_canbedeleted_converted ${out_file}_working_canbedeleted
	else
	        touch ${out_file}_working_canbedeleted
	fi


	echo
	echo "Result saved to:" 
	echo "$out_file"
	echo "${out_file}_with_gz"
	echo "${out_file}_working_canbedeleted"
else
        echo "No files with $ext extension found"
fi
