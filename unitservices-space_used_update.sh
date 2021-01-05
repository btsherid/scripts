#!/bin/bash

#Get last Sunday's date because NetApp stats are run weekly on Sunday
today="$(date +%m-%d-%Y)"
today=${today##*-}-${today%-*}
last_sunday="$(date -d "$today -$(date -d $today +%u) days" +"%Y%m%d")"

stats_file="/datastore/lbgadmin/netapp/netapp-stats/$last_sunday/nextgenout-du"
cifs_file="/datastore/lbgadmin/netapp/netapp-stats/cifs-volume-usage.out"

#Save code of UnitServices page to temp file
php /var/www/environments/prod/www-default/http_sysadminwiki/maintenance/view.php UnitServices > /tmp/unitservices
cp /tmp/unitservices /tmp/unitservices_backups/unitservices.bk.$today

#Get a list of labs to look up sizes for
labs="$(cat /tmp/unitservices | awk -F '|' '{print $2}' | grep lab)"

#Add some static entries to the labs
labs="$labs admin anders_lab bioinformatics-annex-\|5-share-labs-bioinformatics\|histomics hayeslab HealthRegistry herringl_lab ijdavis_lab imgf innocenti_lab ITVS jmcalabr_lab krichards_lab labs nancy_thomas_lab\|melanoma OGR\|UNCseq pmbb proteomics\|protlab protocol ram researchdata seqdata_hosp sharplesslab tgl TPL Vincent_Lab wykimlab"

counter=0

for entry in $labs
do
	#Grep the entry from the stat file
	grep_result="$(grep "$entry" $stats_file | awk '{print $1}')"

	#Grep the entry from the cifs file
	grep_cifs_result="$(grep "$entry" $cifs_file | awk '{print $3}')"

	#If greping the stat file came up with nothing, check if the cifs grep came up with something, it both came up with nothing, set the string to be displayed as 0B
	if [[ "$grep_result" == "" ]]; then
		if ! [[ "$grep_cifs_result" == "" ]]; then
			grep_result=$grep_cifs_result
		else
			grep_result="0B"
		fi
	#If entry is labs, we want the result of greping the cifs file. If greping the cifs file came up with nothing, set the string to be displayed as 0B.
	elif [[ "$entry" == "labs" ]]; then
		if ! [[ "$grep_cifs_result" == "" ]]; then
                        grep_result=$grep_cifs_result
                else
                        grep_result="0B"
                fi
	#If entry is admin, we want the result of greping the cifs file. If greping the cifs file came up with nothing, set the string to be displayed as 0B.
	elif [[ "$entry" == "admin" ]]; then
		if ! [[ "$grep_cifs_result" == "" ]]; then
                        grep_result=$grep_cifs_result
                else
                        grep_result="0B"
                fi
	fi

	#Get a word count of how many entries the grep found
	grep_result_wc="$(echo $grep_result | tr ' ' '\n'  | wc -l)"

	#If grep found more than one entry we need to add them together and get a total
	if [[ $grep_result_wc -gt 1 ]]; then
		#Save grep output to temp file
		echo $grep_result | tr ' ' '\n' > /tmp/grep_result
		
		#Get TB, GB, MB, and KB sizes from temp file
		TB="$(grep T /tmp/grep_result | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
		GB="$(grep G /tmp/grep_result | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
		MB="$(grep M /tmp/grep_result | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
		KB="$(grep K /tmp/grep_result | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
		
		#If a grep returns nothing, set that variable to 0
		if [[ "$TB" == "" ]]; then
		        TB="0"
		fi

		if [[ "$GB" == "" ]]; then
		        GB="0"
		fi
		if [[ "$MB" == "" ]]; then
		        MB="0"
		fi
		
		if [[ "$KB" == "" ]]; then
		        KB="0"
		fi

		#Convert GB, MB, and KB to TB
		GB_to_TB="$(echo "$GB / 1024" | bc -l)"
		MB_to_TB="$(echo "$MB / 1024 / 1024" | bc -l)"
		KB_to_TB="$(echo "$GB / 1024 / 1024" | bc -l)"

		#Add everything together and get a total
		total="$(echo "$TB + $GB_to_TB + $MB_to_TB + $KB_to_TB" | bc -l | xargs printf "%.2f")"

		#Deal with the static entries from the labs variable. If the $entry is a static entry, the search paramater given to awk is different than $entry.
		#For each case, have awk replace the space used value for the columin matching the "size" variable search parameter and save the result to a different temp file.
		#For example, if $entry=admin, have awk search for LCCC IT Admin and replace the space used value in that row.
		if [[ "$entry" == "admin" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" LCCC IT Admin " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "anders_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" lccc_anderslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "bioinformatics-annex-\|5-share-labs-bioinformatics\|histomics" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" parkerjslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "hayeslab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" hayesadm " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "herringl_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" herringlab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "ijdavis_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" davislab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "imgf" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" lccc_imgf " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "innocenti_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" innocentilab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "jmcalabr_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" lccc_jmclab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "krichards_lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" lccc_krichardslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "labs" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" LCCC IT Labs " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "nancy_thomas_lab\|melanoma" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" nancythomas_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "OGR\|UNCseq" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" ogr " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "proteomics\|protlab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" Proteomics Core " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
			mv /tmp/unitservicesautomated /tmp/unitservices
			awk -F '|' -v val=" '''${total}T''' " -v size=" protlab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "protocol" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" LCCC IT Protocol " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "ram" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" lccc_ram " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "researchdata" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" geriatrics " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "seqdata_hosp" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" Hospital MiSeq Instruments " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "sharplesslab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" sharpless_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "tgl" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" TGL " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "Vincent_Lab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" vincent_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		elif [[ "$entry" == "wykimlab" ]]; then
			awk -F '|' -v val=" '''${total}T''' " -v size=" wykim_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		#If the entry is not a static entry, the search parameter given to awk is equal to $entry.
		#Awk replaces the space used value for the colum matching the "size" variable search parameter and saves the result to a differente temp file
		#For example, if $entry=francolab, have awk search for francolab and replace the space used value in that row.
		else
			awk -F '|' -v val=" '''${total}T''' " -v size=" $entry " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		fi
		
		#Remove temp grep file
		rm /tmp/grep_result
	#If grep only finds one entry, no need for a total, just use what grep found to replace the value in the table.
	else
		#Deal with the static entries from the labs variable. If the $entry is a static entry, the search paramater given to awk is different than $entry. 
		#For each case, have awk replace the space used value for the colum matching the "size" variable search parameter and save the result to a different temp file.
		#For example, if $entry=admin, have awk search for LCCC IT Admin and replace the space used value in that row.
		if [[ "$entry" == "admin" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" LCCC IT Admin " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "anders_lab" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" lccc_anderslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "bioinformatics-annex-\|5-share-labs-bioinformatics\|histomics" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" parkerjslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "hayeslab" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" hayesadm " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "herringl_lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" herringlab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "ijdavis_lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" davislab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "imgf" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" lccc_imgf " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "innocenti_lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" innocentilab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "jmcalabr_lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" lccc_jmclab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "krichards_lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" lccc_krichardslab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "labs" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" LCCC IT Labs " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "nancy_thomas_lab\|melanoma" ]]; then	
                        awk -F '|' -v val=" '''$grep_result (n5 only)''' " -v size=" nancythomas_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "OGR\|UNCseq" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" ogr " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "proteomics\|protlab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" Proteomics Core " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
			mv /tmp/unitservicesautomated /tmp/unitservices
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" protlab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "protocol" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" LCCC IT Protocol " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "ram" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" lccc_ram " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "researchdata" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" geriatrics " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "seqdata_hosp" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" Hospital MiSeq Instruments " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "sharplesslab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" sharpless_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "tgl" ]]; then
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" TGL " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "Vincent_Lab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" vincent_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
                elif [[ "$entry" == "wykimlab" ]]; then	
                        awk -F '|' -v val=" '''$grep_result''' " -v size=" wykim_lab " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		#If the entry is not a static entry, the search parameter given to awk is equal to $entry.
                #Awk replaces the space used value for the colum matching the "size" variable search parameter and saves the result to a differente temp file
		#For example, if $entry=francolab, have awk search for francolab and replace the space used value in that row.
		else
			awk -F '|' -v val=" '''$grep_result''' " -v size=" $entry " '$2==size {$10=val}1' OFS='|' /tmp/unitservices > /tmp/unitservicesautomated
		fi

	fi
	#Move the different temp file to the temp file. This makes the file continually update for each entry in the for loop leaving a completed file at the end.
	mv /tmp/unitservicesautomated /tmp/unitservices
done

#Update wiki page
cat /tmp/unitservices |php /var/www/environments/prod/www-default/http_sysadminwiki/maintenance/edit.php "UnitServices" --conf /var/www/environments/prod/www-default/http_sysadminwiki/LocalSettings.php &> /dev/null

#Remove temp file
rm /tmp/unitservices
