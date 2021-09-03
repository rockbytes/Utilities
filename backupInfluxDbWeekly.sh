#!/bin/bash

get_influxdb_data_within_datetime_range() {
	startDatetime=$1
	endDatetime=$2
	outputFile=$3
	
	influxDbUrl='https://xyz.influxcloud.net:8086'
	user='accout:password'
	db='ServiceLevels'
	measurement='loadDuration'
	
	query="SELECT * FROM $measurement WHERE time >= '"
	query+=$startDatetime
	query+="' AND time < '"
	query+=$endDatetime
	query+="'"
	
	curl --ssl -G "$influxDbUrl/query?" -u $user --data-urlencode "db=$db" --data-urlencode "q=$query" > $outputFile
}

get_influxdb_data_weekly() {
	startDateTime=$1
	numberOfWeeks=$2
	outputDir=${3%/}
	
	dtStart=`date -d "$startDateTime"`
	
	cntWeek=0
	while [ $cntWeek -lt $numberOfWeeks ]
	do
		dtEnd=$(date -d "$dtStart + 7 day")

		dtStartStr=$(date +%Y-%m-%dT%H:%M:%SZ -d "$dtStart")
		dtEndStr=$(date +%Y-%m-%dT%H:%M:%SZ -d "$dtEnd")
		
		outputFile=$outputDir
		outputFile+='/'
		outputFile+=$(date +%Y-%m-%dT%H-%M-%SZ -d "$dtStart")
		outputFile+='_'
		outputFile+=$(date +%Y-%m-%dT%H-%M-%SZ -d "$dtEnd")
		outputFile+='.json'
		
		echo "Dumping data into $outputFile"
		get_influxdb_data_within_datetime_range $dtStartStr $dtEndStr $outputFile
		
		dtStart=$dtEnd
		cntWeek=$[$cntWeek+1]
	done
}


startDateTime=$1
numberOfWeeks=$2
outputDir=$3

get_influxdb_data_weekly $startDateTime $numberOfWeeks $outputDir