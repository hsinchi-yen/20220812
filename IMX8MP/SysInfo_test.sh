#!/bin/bash
: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Dump the system info. - Yocto ver/Kernel/cpu/mem/emmc size /emmc life for inspection
 OS_Platform       : Yocto 3.3
 Script name       : SysInfo_test.sh
 Author            : lancey
 Date created      : 20220810
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20220810    lancey      1      Initial draft for test
************************************************************************
'

SYSINFOLOG="/tmp/systeminfolog.txt"
eMMCID="2"

DivderLine()
{
  #
  #$1 print symbol, #$2 loop time ,
  for (( i = 0; i < $2; i++ )); do
      echo -ne "${1}"
  done
  echo -ne "\n"
}

#----start  all parameters ---

#get board info
#get the SOC ID , SOC version, Family, soc_serial number
BOARDINFO=$(cat /sys/devices/soc0/machine)
SOCFAMILY=$(cat /sys/devices/soc0/family)
SOCREV=$(cat /sys/devices/soc0/revision)
SOCID=$(cat /sys/devices/soc0/soc_id)
SOC_SN=$(cat /sys/devices/soc0/serial_number)

#CPU : ID, freqs for cur,idel,max, temp
#Display CPU Cur/Max/Min Clock
#get the qty of SOC
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)
#get the CPU current speed
CPU_CUR_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq | awk '{$1=$1/1000; print $1;}')
CPU_MAX_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq | awk '{$1=$1/1000; print $1;}')
CPU_MIN_CLK=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq | awk '{$1=$1/1000; print $1;}')
# get the current temperature of CPU
CPU_TEMP_Z1=$(cat /sys/class/thermal/thermal_zone0/temp| awk '{$1=$1/1000; print $1;}')
CPU_TEMP_Z2=$(cat /sys/class/thermal/thermal_zone1/temp | awk '{$1=$1/1000; print $1;}')

#get eMMC name, vdd, chip select, bus width , time spec, signal voltage
#pase emmc info from dmesg
EMMC_NAME=$(dmesg | grep "mmcblk${eMMCID}" | grep GiB | head -1 | awk -F ' ' '{print $5}')
EMMC_SIZE=$(dmesg | grep "mmcblk${eMMCID}" | grep GiB | head -1 | awk -F ' ' '{print $6 $7}')
EMMC_freespace=$(df -h | grep "/dev/root" | awk -F ' ' '{print $4}')
#eMMC version, life , operation state
EMMC_VER=$(mmc extcsd read /dev/mmcblk${eMMCID} | grep "Extended CSD rev" | sed 's/^ *//')
EMMC_LIFE=$(mmc extcsd read /dev/mmcblk${eMMCID} | grep "eMMC Life")
EMMC_PEOL=$(mmc extcsd read /dev/mmcblk${eMMCID} | grep "eMMC Pre EOL")
EMMC_OP_State=$(cat "/sys/kernel/debug/mmc${eMMCID}/ios")

#Get memory size, CMA size
MEMSIZE=$(free -h | grep 'Mem:' | awk -F ' ' '{print $2}')
used_MEMSIZE=$(free -h | grep 'Mem:' | awk -F ' ' '{print $3}')
free_MEMSIZE=$(free -h | grep 'Mem:' | awk -F ' ' '{print $4}')
CMASIZE=$(cat /proc/meminfo | grep CmaTotal | awk -F ' ' '{$2=$2/1000; print $2}')
free_CMASIZE=$(cat /proc/meminfo | grep CmaFree | awk -F ' ' '{$2=$2/1000; print $2}')

#GPU info , module, working Clock
GPU_INFO=$(cat /sys/kernel/debug/gc/info)
GPU_M_INFO=$(cat /sys/kernel/debug/gc/meminfo)

#Network , eth name, wifi chip name, btchip name , bt version, wifi chip temp
ETH_MACID=$(ifconfig eth0 | grep -E "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w" | awk -F ' ' '{print $2}')
ETH_INF=$(ifconfig eth0 | grep "eth0" | awk -F ':' '{print $1}')
ETH_CHIP_ID=$(dmesg | grep eth | grep driver | awk -F '[' '{print $4}' | awk -F ']' '{print $1}')
WIFI_MACID=$(ifconfig wlan0 | grep -E "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w"  | awk -F ' ' '{print $2}')
WIFI_INF=$(ifconfig wlan0 | grep "wlan0" | awk -F ':' '{print $1}')
WIFI_CHIPID=$(cat /sys/bus/mmc/devices/mmc?\:0001/mmc?\:0001\:1/device)
WIFI_FWINFO=$(dmesg | grep "HW:" | awk -F ']' '{print $2}')


BT_MACID=$(hciconfig -a | grep -E "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w" | awk -F ' ' '{print $3}')
BT_VER=$(hciconfig -a | grep "HCI Version" | awk -F ' ' '{print $3}')
BT_INF=$(hciconfig -a | grep hci | awk -F ':' '{print $1}')

WIFI_CHIP_INFO=$(iwpriv wlan0 get_temp)
WIFI_CHIP_INF=$(echo "$WIFI_CHIP_INFO" | cut -d ' ' -f 1)
WIFI_CHIP_TEMP=$(echo "$WIFI_CHIP_INFO" | cut -d ':' -f 2)

{
#----end all parameters ---
DivderLine "-" 80
echo "System"
DivderLine "-" 80
printf "Board informaion :\t${BOARDINFO}\n"
printf "SOC FAMILY :\t\t${SOCFAMILY}\n"
printf "SOC Revision :\t\t${SOCREV}\n"
printf "SOC ID :\t\t${SOCID}\n"
printf "SOC SN :\t\t${SOC_SN}\n"
DivderLine "-" 80

echo "CPU information"
DivderLine "-" 80
#Display CPU related info and temperature
printf "CPU Current Speed (MHz) : \t ${CPU_CUR_CLK}\n"
printf "CPU core : \t${CPUS}\n"
printf "CPU Maximun clock (Mhz): \t ${CPU_MAX_CLK}\n"
printf "CPU Minimun clock (Mhz): \t ${CPU_MIN_CLK}\n"
echo ""
printf "CPU temperature,Zone0 : \t ${CPU_TEMP_Z1} DegC.\n"
printf "CPU temperature,Zone1 : \t ${CPU_TEMP_Z2} DegC.\n"

DivderLine "-" 80
echo "Internal Memory information"
DivderLine "-" 80
echo "Total Memory Capacity : ${MEMSIZE}, used : ${used_MEMSIZE}, free : ${free_MEMSIZE}"
echo "eMMC Capacity : ${EMMC_SIZE}, free : ${EMMC_freespace}"
echo "CMA Memory Size : ${CMASIZE}, free CMA : ${free_CMASIZE}"
DivderLine "-" 80

echo "EMMC Information"
DivderLine "-" 80
echo "eMMC Name : $EMMC_NAME"
echo "eMMC Capacity : ${EMMC_SIZE}"
echo "eMMC version : ${EMMC_VER}"
echo "${EMMC_LIFE}"
echo "${EMMC_PEOL}"
DivderLine "-" 40
echo "eMMC Operation state"
DivderLine "-" 40
echo "${EMMC_OP_State}"

DivderLine "-" 80
echo "Network"
DivderLine "-" 80
printf "Ethernet : ${ETH_CHIP_ID}\n"
printf "Interface : ${ETH_INF}\n"
printf "MAC address : ${ETH_MACID}\n"
DivderLine "-" 40
printf "WiFi Interface : ${WIFI_INF}\n"
printf "MAC address : ${WIFI_MACID}\n"
printf "Chip Temp : ${WIFI_CHIP_TEMP}\n"
printf "WIFI CHIP ID : ${WIFI_CHIPID}\n"
printf "WiFi Firmware info : ${WIFI_FWINFO}\n"
DivderLine "-" 40
printf "Bluetooth : ${BT_INF}\n"
printf "MAC address : ${BT_MACID}\n"
printf "BT Version : ${BT_VER}\n"

BT_MACID=$(hciconfig -a | grep -E "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w")
BT_VER=$(hciconfig -a | grep "HCI Version" | awk -F ' ' '{print $3}')
BT_INF=$(hciconfig -a | grep hci | awk -F ':' '{print $1}')

DivderLine "-" 80

#get eMMC location
#MMCLOC=$(lsblk | grep mmcblk | awk 'FNR ==1 {print $1}')

echo "Image - OS - Kernel - Uboot Version Information "
DivderLine "-" 80
cat /etc/os-release
cat /proc/version
# get the U-boot info.
dd if=/dev/'mmcblk${eMMCID}' skip=32 bs=1k count=1200 2>/dev/null | strings | grep 'U-Boot' | head -1
sleep 0.2
#DivderLine "-" 80
echo ""
#redirect the test output to /tmp/folder
} | tee -a ${SYSINFOLOG}
