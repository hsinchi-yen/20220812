: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Test Bluetooth - A2DP_sink, bluetoothctl connection and playback audio with BT speaker
 Script name       : BT_A2DP_test.sh
 Author            : lancey
 Date created      : 20220805
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20220804    lancey      1      Initial draft for test
************************************************************************
'

#!/bin/bash

#BT speaker Test
#Devices info and define variables
BT_Device_ID="E8:07:BF:6F:B4:99"
BT_Device_Name="Mi Bluetooth Speaker"
BTmsg="/tmp/BTmsg.txt"

ClrPulseAudio()
{
  platform=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
  platform=$(echo $platform | tr '[:upper:]' '[:lower:]')

  case "${platform}" in

    *imx8*)
            echo "64 bit SOC"
            while true; do pulseaudio -k; pulseaudio > /dev/null 2>&1 & PID=$! && sleep 1; ( ps -p $PID > /dev/null ) && break; done
            ;;

    *)
            echo "32 bit SOC"
            export DISPLAY=:0; killall pulseaudio; pulseaudio -D
            ;;
  esac

}

#Restart the pluseaudio service
ClrPulseAudio
BTstatus=$(hciconfig hci0 -a | grep "UP RUNNING")

if [[ -n $BTstatus ]]; then
  echo "The BT device is UP and Running"
else
  echo "The BT device is DOWN, please check the BT device state"
fi

#intiate bluetoothctl utilit in background.
for (( i = 0; i <=10; i++ )); do
  coproc bluetoothctl
  #get the process id
  bt_proc_id=$!
  echo "Process ID : ${bt_proc_id}"

  #send command to bluetoothctl
  echo -e "scan on\n" >&${COPROC[1]}
  sleep 10
  echo -e "scan off\n" >&${COPROC[1]}
  echo -e "exit\n" >&${COPROC[1]}
  cat <&${COPROC[0]} > $BTmsg
  sync
  sleep 0.2
  FoundDEVS=$(cat $BTmsg | grep "NEW" | grep "${BT_Device_Name}" | grep "${BT_Device_Name}")
  sleep 1

  if [[ -n $FoundDEVS ]]; then
    echo "Device found"
    echo $FoundDEVS
    break
  else
    echo "Keep searching"
  fi
done

#start to connect while device available
if [[ -n $FoundDEVS ]]; then
  sleep 1
  coproc bluetoothctl
  echo -e "agent on\n" >&${COPROC[1]}
  echo -e "pair ${BT_Device_ID}\n" >&${COPROC[1]}
  sleep 3
  echo -e "connect ${BT_Device_ID}\n" >&${COPROC[1]}
  sleep 3
  echo -e "quit\n" >&${COPROC[1]}
  cat <&${COPROC[0]} > $BTmsg
  cat $BTmsg

  echo "Display Pluseaudio device"
  pactl list cards short
  pactl set-card-profile $(pactl list cards short | grep bluez | cut -f1) a2dp_sink
  echo "Play sound file for tesing the A2DP_Sink :"
  paplay -p --device=$(pacmd list-sinks | grep -e 'name: <bluez' | cut -c9-46) /usr/share/sounds/alsa/Front_Center.wav

  if [[ $? == 0 ]]; then
    echo "BT A2DP Test : PASS"
  else
    echo "BT A2DP Test : FAIL"
  fi

else
  echo "The ${BT_Device_Name} is not found ..."
  echo "The test won't be completed"
  echo "BT A2DP Test : FAIL"
fi
