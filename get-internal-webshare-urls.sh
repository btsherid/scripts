#!/bin/bash

CONF_DIR="/etc/httpd/conf/sites/default/webshare-internal/webshares/"

#Get all aliases from conf files
aliases=$(grep 'Alias' ${CONF_DIR}*.conf | grep -v 'ScriptAlias' | awk '{print $2}')

#Get a list of conf file names, remove ".conf"
conf_files=$(ls ${CONF_DIR}*.conf | awk -F "/" '{print $9}' | awk -F "." '{print $1}')

for entry in $conf_files
do
if ! [ $entry == "lbg" ]; then

	#If not lbg.conf, parse paths from current conf file
	current_paths="$(grep "<Directory" ${CONF_DIR}${entry}.conf | awk '{print $2}' | grep -o "${entry}.*" | tr -d ">\"" | awk '{print "/"$0}')"

	#Loop through current paths and extract the AuthType for each path
	for path in $current_paths
	do
		#Get line number that the path string is on
		line_number=$(grep -n $path ${CONF_DIR}${entry}.conf | awk -F ":" '{print $1}' | tr "\n" " " | awk '{print $1 }')
		
		#Use the line number to search only that Directory block for the AuthType
		AuthType=$(sed -n "${line_number},/<\/Directory/ p" ${CONF_DIR}${entry}.conf | grep -v 'Directory' | grep AuthType | grep -v "#" | awk '{print $2}')
		
		#If the AuthType check above returns blank, it is not present in that Directory block
		if [[ -z $AuthType ]]; then
			
			#Get the top level directory (e.g. the top level directory for /lbg/experiments is /lbg
			top_level_dir=$(echo $path | awk -F "/" '{print $2}')

			#If the path has more than one word in it, it is a subdirectory.
			#In that case, we want to set its AuthType to the AuthType of the top level directory.
			if [[ $(echo $path | tr '/' ' ' | sed -e 's/^[ \t]*//' | wc -w) >1 ]]; then
				AuthType=$(echo $path_and_auth_type | grep -o "${top_level_dir}-.*" | awk '{print $1}' | awk -F '-' '{print $2}')

			#If the path is a top level directory and the AuthType check returned blank,
			#we want to set the AuthType to None.
			else
				AuthType="None"
			fi	
		fi

		#Append path and AuthType to list of paths and AuthTypes
		path_and_auth_type="$path_and_auth_type ${path}-${AuthType}"
		
	done
else 

	#If lbg.conf, extra parsing is required because the "lbg" substring appears twice (e.g. /datastore/lbgwebshare/webfiles/lbg)
	current_paths="$(grep '<Directory' ${CONF_DIR}${entry}.conf | awk '{print substr($2, 1, length($2)-1)}' | awk -F "/" '{ for(i=5; i<NF; i++) printf "%s",$i OFS; if(NF) printf "%s",$NF; printf ORS}' | tr ' ' '/' | awk '{print "/"$0}' | tr -d '"')"

	#Loop through current paths and extract the AuthType for each path
	for path in $current_paths
        do
		#Get line number that the path string is on
                line_number=$(grep -n $path ${CONF_DIR}${entry}.conf | awk -F ":" '{print $1}' | tr "\n" " " | awk '{print $1 }')
	
		#Use the line number to search only that Directory block for the AuthType
                AuthType=$(sed -n "${line_number},/<\/Directory/ p" ${CONF_DIR}${entry}.conf | grep -v 'Directory' | grep AuthType | grep -v "#" |  awk '{print $2}')

		#If the AuthType check above returns blank, it is not present in that Directory block

		if [[ -z $AuthType ]]; then

                        #Get the top level directory (e.g. the top level directory for /lbg/experiments is /lbg
                        top_level_dir=$(echo $path | awk -F "/" '{print $2}')

                        #If the path has more than one word in it, it is a subdirectory.
                        #In that case, we want to set its AuthType to the AuthType of the top level directory.
                        if [[ $(echo $path | tr '/' ' ' | sed -e 's/^[ \t]*//' | wc -w) >1 ]]; then
                                AuthType=$(echo $path_and_auth_type | grep -o "${top_level_dir}-.*" | awk '{print $1}' | awk -F '-' '{print $2}')

                        #If the path is a top level directory and the AuthType check returned blank,
                        #we want to set the AuthType to None.
                        else
                                AuthType="None"
                        fi
                fi

		#Append path and AuthType to list of paths and AuthTypes
                path_and_auth_type="$path_and_auth_type ${path}-${AuthType}"

        done
 
	
fi

done

#Add new lines to list of paths and AuthTypes. This is necessary for the next step.
for entry in $path_and_auth_type
do
	formatted_path_and_auth_type="${formatted_path_and_auth_type}\n$entry"
done

#Remove duplicate entries
unique_path_and_auth_type=$(echo -e $formatted_path_and_auth_type | uniq)

#Loop through the list of aliases. If the alias does not already exist in the list of unique paths, add it.
#Also, dtermine what the alias points to and save that in the output.
for entry in $aliases
do
	if ! [[ $(echo $unique_path_and_auth_type | grep -o $entry) ]]; then
		for file in $conf_files
		do
			if [[ $(grep $entry ${CONF_DIR}${file}.conf) ]]; then
				alias_target=$(grep "Alias $entry" ${CONF_DIR}${file}.conf | awk '{print $3}' | grep -o "${file}.*" | tr -d ">\"" | awk '{print "/"$0}')  	
				unique_path_and_auth_type="${unique_path_and_auth_type} ${entry}-Alias(for:$alias_target)"
			fi
		done
	fi	
done

#Print output
for entry in $unique_path_and_auth_type
do
	output_path=$(echo $entry | awk -F "-" '{print $1}')
	output_AuthType=$(echo $entry | awk -F "-" '{print $2}')
	output="${output}\nhttps://<internal webshare URL>${output_path} $output_AuthType"
done

echo -e $output | column -t
