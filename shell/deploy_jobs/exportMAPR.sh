#!/bin/bash
# Splunk to Hadoop Script
# Author: Steve Warburton
# version 0.1
# 
# This script issues a GET request to Splunk to pull down data for customers of GDT
# It is configured to read from a csv file with 3 columns which are used for 
# determing where the file will be saved and which data sets we want to grab.
#  
# 1) Read CSV
# 2) Use Date Column to construct File Destination File Path
# 3) Use Start and End dates to complete the Splunk Search Variables
# 4) Issue a REST Call to Splunk SH, perform a search and output the data to /tmp
# 5) Perform File Analytics and Log them Splunk
# 6) Compress File in .bz2 format using lbzip2
# 7) Take a Md5sum of the compressed file and add it to the file name
# 8) Transfer .bz2 to Final Destination on the Hadoop File System
# 
#####################################################################################3

#Set up Global Variables
user=svc_act1
pass=H0TPizzzaT0pp1ngs!

#Log out Data
LOG=/var/log/spl2hdp/exportstatus.out
if [ ! -f $LOG ]; then
    touch $LOG
fi 

#Add Date to Logging File
adddate(){
    while IFS= read -r line; do
        printf '%s %s %s\n' "${date}" "${hostname}" "$line";
    done
}

#Get Input
INPUT=/tmp/exportMAPR/testloopBDE-921.csv
OLDIFS=$IFS
IFS=,

echo "Starting the Splunk to Hadoop Script" | adddate >> $LOG

  #If there is no input, you're going to have a bad time.
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

  # Read the CSV and do stuff with the columns
while read date start end 
do
  #Set our temporary download path.  Files are saved here for compression
  #before they are moved to their final destination.
  TMPPATH=/tmp
  
  #Set our final destination for the files we are grabbing.
  FINALPATH=/hadoop/bdh/raw/eli/CXP/cwp/2019/export/${date}
  
  #If the Final Destination doesn't exist, create it.  Fate is envitable. 
  if [ ! -d $FINALPATH ]; then
     mkdir -p $FINALPATH
  fi
  
  #Establish our File Name
  OUTFILE=cwp-cwp_marketing_logs-${start}-${end}
  
  #Tell the good people which segment we're working on.
  echo "Working on ${date} starting at ${start} and ending at ${end}" 
  
  #Get the Data
  echo "Starting Data Retrieval $(`date '+%m-%y-%d-%h-%m-%s'`) for ${date}; segment ${start} to ${end}" | adddate >> $LOG
  curl -k -u $user:$pass https://s3140some_loc:8089/services/search/jobs/export -d search="search index=cwp sourcetype=cwp_marketing_logs _index_earliest=${start} _index_latest=${end} | fields _raw" -d output_mode="raw" > "$TMPPATH/$OUTFILE"
  
  #Get our Analytics out of the way
  Lines=$(wc -l "$TMPPATH/$OUTFILE")
  Words=$(wc -w "$TMPPATH/$OUTFILE") 
  FILESIZE=$(stat -c%s "$TMPPATH/$OUTFILE")
  echo ""$TMPPATH/$OUTFILE" received with $Lines Lines and $Words Words with a File Size of $FILESIZE." | adddate >> $LOG
  
  #Compress the Data
  echo "Compressing the Data" | adddate >> $LOG
  lbzip2 "$TMPPATH/$OUTFILE"
  
  #Let's take a MD5SUM
  md5sum=md5sum "$TMPPATH/$OUTFILE.bz2"
  
  #Relocate the Data to the Final destination
  echo "Job Complete" 
  echo "File is now stored in HDFS" | adddate >> $LOG
  mv "$TMPPATH/$OUTFILE.bz2" "$FINALPATH/$OUTFILE-$md5sum.bz2"
done < $INPUT
IFS=$OLDIFS
