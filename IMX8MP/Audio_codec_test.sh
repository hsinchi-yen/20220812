: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Test GPU performance with built-in utility.
 Script name       : Audio_codec_test.sh
 Author            : lancey
 Date created      : 20220809
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
DL_AUDIOFILES="Audios.gz"
FILESERVER="10.88.88.229"
AUDIOTESTLOG=/tmp/audio_test_log.txt

#downfiles from server

volume_set()
{
  echo "Adjust volume to ${2} for testing"
  #$1 = CARD ID
  #$2 = Volume Value

  amixer -c ${1} sset 'Headphone' ${2}
  amixer -c ${1} sset 'Headphone Playback ZC' ${2}
  amixer -c ${1} sset 'Speaker' ${2}
  amixer -c ${1} sset 'Playback' ${2}
}


if [[ ! -d Audios ]]; then
  wget "http://${FILESERVER}/Audios/${DL_AUDIOFILES}"
  isDonloaded=$?

  if [[ $isDownloaed -eq 0 ]]; then
    #extract
    tar -vxf ${DL_AUDIOFILES}
    sleep 1
    sync
    rm Audios.gz
  else
    echo "Please check connection of the FILE Server:${FILESERVER}"
  fi
fi

#goto forder
cd Audios

#display audio codec name & codec id
#play with HW codec
SNDCARDID=$(aplay -l | grep -E "wm89|sgtl5000" | head -1 | awk '{print $2}' | cut -d ':' -f1)

#set volume_set
volume_set ${SNDCARDID} 90

aud_codecname=$(cat "/proc/asound/card${SNDCARDID}/id")
echo "Audio codec name : ${aud_codecname}, Audio card ID : ${SNDCARDID}"

AUDFILES=$(find ./ -type f | grep .wav | cut -d "/" -f2 | sort -n)

#start to test audio files
echo "audio codec test with codec itself"
for aud in $AUDFILES; do
  echo "Audio File : $aud"
  sleep 1
  echo "testing : aplay -Dhw:${SNDCARDID} ${aud}"
  aplay -Dhw:${SNDCARDID} ${aud}
  playresult=$?
  #echo $playresult

  if [[ $playresult -eq 0 ]]; then
    echo "Sample wav : ${aud} , Test : PASS"
  else
    echo "Sample wav : ${aud} , Test : FAIL"
  fi

done

#play with CPU's codec

echo "audio codec test with CPU"
for aud in $AUDFILES; do
  echo "Audio File : $aud"
  sleep 1
  echo "testing : aplay -D plughw:${SNDCARDID} ${aud}"
  aplay -D plughw:${SNDCARDID} ${aud}
  playresult=$?
  #echo $playresult

  if [[ $playresult -eq 0 ]]; then
    echo "Sample wav : ${aud} , Test : PASS"
  else
    echo "Sample wav : ${aud} , Test : FAIL"
  fi

done

#goto forder
cd ..

#display result
#write log
