#!/bin/bash

path=$1
excludes=$2 

if [[ "$excludes" == "" ]]; then
	subdirs_depth1="$(find $path -maxdepth 1 -mindepth 1 -type d 2> /dev/null)"
	files_depth1="$(find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null)"
else 
	subdirs_depth1="$(find $path -maxdepth 1 -mindepth 1 -type d 2> /dev/null | grep -v "$excludes")"
	files_depth1="$(find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes")"
fi
subdirs_count_depth1="$(echo $subdirs_depth1 | tr ' ' '\n' | wc -l)"
subdirs_count_depth2="0"
subdirs_count_depth3="0"
subdirs_count_depth4="0"
subdirs_count_depth5="0"
depth_to_use="1"

if [[ "$subdirs_count_depth1" -lt "15" ]]; then
	if [[ "$excludes" == "" ]]; then
		subdirs_depth2="$(find $path -maxdepth 2 -mindepth 2 -type d 2> /dev/null)"
		files_depth2="$(find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null)"
	else
		subdirs_depth2="$(find $path -maxdepth 2 -mindepth 2 -type d 2> /dev/null | grep -v "$excludes")"
		files_depth2="$(find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | grep -v "$excludes")"
	fi
	if ! [[ "$subdirs_depth2" == "" ]]; then
		subdirs_count_depth2="$(echo $subdirs_depth2 | tr ' ' '\n' | wc -l)"
		depth_to_use="2"
	fi
fi

if [[ "$subdirs_count_depth2" -ne "0" && "$subdirs_count_depth2" -lt "15" ]]; then
	if [[ "$excludes" == "" ]]; then
		subdirs_depth3="$(find $path -maxdepth 3 -mindepth 3 -type d 2> /dev/null)"
		files_depth3="$(find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null)"
	else
		subdirs_depth3="$(find $path -maxdepth 3 -mindepth 3 -type d 2> /dev/null | grep -v "$excludes")"
		files_depth3="$(find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | grep -v "$excludes")"
	fi
subdirs_count_depth3="$(echo $subdirs_depth3 | tr ' ' '\n' | wc -l)"
depth_to_use="3"
fi

if [[ "$subdirs_count_depth3" -ne "0" && "$subdirs_count_depth3" -lt "15" ]]; then
	if [[ "$excludes" == "" ]]; then
		subdirs_depth4="$(find $path -maxdepth 4 -mindepth 4 -type d 2> /dev/null)"
		files_depth4="$(find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null)"
	else
		subdirs_depth4="$(find $path -maxdepth 4 -mindepth 4 -type d 2> /dev/null | grep -v "$excludes")"
		files_depth4="$(find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null | grep -v "$excludes")"
	fi
subdirs_count_depth4="$(echo $subdirs_depth4 | tr ' ' '\n' | wc -l)"
depth_to_use="4"
fi

if [[ "$subdirs_count_depth4" -ne "0" && "$subdirs_count_depth4" -lt "15" ]]; then
	if [[ "$excludes" == "" ]]; then
		subdirs_depth5="$(find $path -maxdepth 5 -mindepth 5 -type d 2> /dev/null)"
		files_depth5="$(find $path -maxdepth 5 -mindepth 5 -type f 2> /dev/null)"
	else
		subdirs_depth5="$(find $path -maxdepth 5 -mindepth 5 -type d 2> /dev/null | grep -v "$excludes")"
		files_depth5="$(find $path -maxdepth 5 -mindepth 5 -type f 2> /dev/null | grep -v "$excludes")"
	fi
subdirs_count_depth5="$(echo $subdirs_depth5 | tr ' ' '\n' | wc -l)"
depth_to_use="5"
fi

case $depth_to_use in
	1) 
	  if [[ "$excludes" == "" ]]; then
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 1 -mindepth 1 -type d 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  else
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 1 -mindepth 1 -type d 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  fi
	  ;;
	2) 
	  if [[ "$excludes" == "" ]]; then
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type d 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  else
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type d 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  fi
	  ;;
	3)
	  if [[ "$excludes" == "" ]]; then
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type d 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  else
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type d 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  fi
	  ;;
	4)
	  if [[ "$excludes" == "" ]]; then
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type d 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  else
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type d 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  fi
	  ;;
	5)
	  if [[ "$excludes" == "" ]]; then
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 5 -mindepth 5 -type f 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 5 -mindepth 5 -type d 2> /dev/null | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  else
		  find $path -maxdepth 1 -mindepth 1 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 2 -mindepth 2 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 3 -mindepth 3 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 4 -mindepth 4 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai "%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 5 -mindepth 5 -type f 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *.bai"%" "/NS/lccc-gcp-archive/%"
		  find $path -maxdepth 5 -mindepth 5 -type d 2> /dev/null | grep -v "$excludes" | xargs -n1 -P10 -I% rsync -avz --specials --progress --no-links --exclude *.bam --exclude *bai "%/" "/NS/lccc-gcp-archive/%/"
		  exit $?
	  fi
	  ;;
	*)
	  echo "Subdirectory depth to use not found"
	  exit 1
esac
