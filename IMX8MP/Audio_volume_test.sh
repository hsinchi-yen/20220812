: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Test Volume and mute function for audio codec.
 Script name       : Audio_volume_test.sh
 Author            : lancey
 Date created      : 20220810
 Applied platform  : Yocto 3.3 / imx8
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20220809    lancey      1      Initial draft for test
************************************************************************
'

#!/bin/bash

#parameters
TEST_AUDIOFILES="/run/media/mmcblk2p2/usr/share/sounds/alsa/"

#downfiles from server

is_alsa_wav()
{
  isFile=$(find / | grep "/usr/share/sounds/alsa/Front_Center.wav")

  if [[ -z ${isFile} ]]; then
    return 1
  else
    #echo "Audio file list"
    #echo "${isFile}" | grep "mmcblk"
    return 0
  fi
}

volume_set()
{
  if [[ ${3} == "" ]]; then
    echo "Adjust volume to ${2} for testing"
  fi

  #$1 = CARD ID
  #$2 = Volume Value
  amixer -c ${1} sset 'Headphone' ${2} >/dev/null 2>&1
  amixer -c ${1} sset 'Headphone Playback ZC' ${2} >/dev/null 2>&1
  amixer -c ${1} sset 'Speaker' ${2} >/dev/null 2>&1
  amixer -c ${1} sset 'Playback' ${2} >/dev/null 2>&1
}

alsaplay()
{
  #$1 = SNDCARDID
  #$2 = volume Value
  #$3 = alsafile
  local SNDCARDID=$1
  local vl=$2
  local alsafile=$3

  volume_set ${SNDCARDID} ${vl}

  if [[ ${vl} -eq 0 ]]; then
     echo "Test Volume : ${vl}% , MUTE"
  else
     echo "Test Volume : ${vl}%"
  fi

  #play with CPU's codec
  #echo "audio codec test with CPU"

  for aud in $alsafile; do
      #echo "Audio File : $aud"
      #echo "testing : aplay -D plughw:${SNDCARDID} ${aud}"
      aplay -D plughw:${SNDCARDID} ${aud} > /dev/null 2>&1
      #echo $playresult
      playresult=$?
      sleep 0.5

      if [[ $playresult -eq 0 ]]; then
        echo "Volume ${vl}% , Test : PASS"
      else
        echo "Volume ${vl}% , Test : FAIL"
      fi

  done
}


is_alsa_wav
alsa_filestatus=$?

if [[ ${alsa_filestatus} -eq 1 ]]; then
  echo "The system has no built-in alsa - wav test files."
  echo "Please consult SW RD for this issue."
else
  #generate audio play array
  alsafile=$(find / -type f | grep "/usr/share/sounds/alsa/Front_Center.wav")

  #display audio codec name & codec id
  #play with HW codec
  SNDCARDID=$(aplay -l | grep -E "wm89|sgtl5000" | head -1 | awk '{print $2}' | cut -d ':' -f1)

  #set volume_set

  aud_codecname=$(cat "/proc/asound/card${SNDCARDID}/id")
  echo "Audio codec name : ${aud_codecname}, Audio card ID : ${SNDCARDID}"

  #vl = volume value test from volume down to up
  for vl in {0..100..25}; do
      alsaplay ${SNDCARDID} ${vl} ${alsafile}
  done

  #vl = volume value test from volume up to down
  for vl in {75..0..-25}; do
      alsaplay ${SNDCARDID} ${vl} ${alsafile}
  done

  echo "Volume test is completed!"

  #return the default setting
  volume_set ${SNDCARDID} 80 "suppression"
fi
