#!/bin/bash

: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Sub functions for test scripts and extra parameters.
 Script name       : conf_subfuncs.sh
 Author            : lancey
 Date created      : 20220808
 Applied platform  : Yocto 3.0 / imx8
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20220808    lancey      1      Initial draft for test
************************************************************************
'
#Get Date and Time
GetTime()
{
  rtime=$(date +"%Y-%m-%d %H:%M:%S")
  echo $rtime
}

#Get System seconds
GetCurSecond()
{
  rseconds=$(date +%s)
  echo $rseconds
}

#Convert seconds to minutes
secs_to_human() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}
