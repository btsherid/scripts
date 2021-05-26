#!/bin/bash
volumes="alldata clustersysshare home1 home2 home3 home4 mapseq-analysis nextgenout2 nextgenout3 nextgenout4 nextgenout5 peroulab seqdata seqdata_hosp seqware-analysis"
group="$1"
out_file="/tmp/$1_files"
out_file_dirs="/tmp/${group}_dirs"

truncate -s 0 $out_file

echo "*****Searching for files owned by by $group*****"
for entry in $volumes
do
echo "Searching $entry"
sf query $entry: -d , -h --groupname $1 --format "vol_path username uid groupname size ct" >> $out_file
done

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

echo "*****Removing unneeded lines*****"
sed -i '/vol_path/d' $out_file

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
if test -f "${out_file}.exists"
then

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

	echo "*****Converting timestamps to human readable dates*****"
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
	echo "*****Extracting directories from files*****"
	awk -F '/' '{print "/"$2"/"$3"/"$4"/"$5}' $out_file | awk -F ',' '{print $1}' | sort -u > $out_file_dirs
	echo >> $out_file_dirs
	echo "/datastore/nextgenout2/share/labs directories:" >> $out_file_dirs
	grep "nextgenout2/share/labs" $out_file | awk -F '/' '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | awk -F ',' '{print $1}' | sort -u >> $out_file_dirs
	echo >> $out_file_dirs
        echo "/datastore/nextgenout3/share/labs directories:" >> $out_file_dirs
        grep "nextgenout3/share/labs" $out_file | awk -F '/' '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | awk -F ',' '{print $1}' | sort -u >> $out_file_dirs
	echo >> $out_file_dirs
        echo "/datastore/nextgenout4/share/labs directories:" >> $out_file_dirs
        grep "nextgenout4/share/labs" $out_file | awk -F '/' '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | awk -F ',' '{print $1}' | sort -u >> $out_file_dirs
	echo >> $out_file_dirs
        echo "/datastore/nextgenout5/share/labs directories:" >> $out_file_dirs
        grep "nextgenout5/share/labs" $out_file | awk -F '/' '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | awk -F ',' '{print $1}' | sort -u >> $out_file_dirs

	echo "Result saved to:"
	echo "$out_file"
	echo "$out_file_dirs"
else
	echo "No files owned by $group found"
fi
