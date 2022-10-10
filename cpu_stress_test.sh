#!/bin/bash

: '
Script name : cpu_stress_test.sh

-------------------------------------------------------------
date        author          purpose
-------------------------------------------------------------
20221009    lancey          intitial draft
-------------------------------------------------------------
'
TEST_TIME=3600
TEST_PERIOD=600
CPU_LOAD=50
CPU_BURN_TEST_LOG=/tmp/cpu_burn_testlog.txt

run_cpu_stressor()
{
  local cpu_streessor_pid
  #stressapptest -c 2 -M 1000 -s ${TEST_TIME} > /tmp/stressapp.log &
  stress-ng -c 0 -l ${CPU_LOAD} -t ${TEST_TIME} > /dev/null 2>1&
  cpu_streessor_pid=$!
  echo "${cpu_streessor_pid}"
}

get_cpu_usage()
{
  local cpu_rate
  #first way for get cpu usage
  #cpu_rate=$(top -n 1 -b | awk '/^%Cpu/{print $2}')
  #second way for get cpu usage
  cpu_rate=$(top -bn1 | grep "stress" | head -1 | awk -F ' ' '{print $9}')
  echo "${cpu_rate}"
}

get_cpu_temp()
{
  #local cpu_raw_temp
  local cpu_temp
  #cpu_raw_temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp)
  cpu_temp=$(sensors | grep "Package" | awk -F ' ' '{print $4}')
  echo "${cpu_temp}"
}

cpu_test_logfile_headergen()
{
  if [[ -f ${CPU_BURN_TEST_LOG} ]]; then
    rm -f ${CPU_BURN_TEST_LOG}
  fi
  touch ${CPU_BURN_TEST_LOG}
  echo -e "TIME\t\t\tCPUrate\t\tCPU_TEMP" >> ${CPU_BURN_TEST_LOG}
  echo -e "================================================================================="  >> ${CPU_BURN_TEST_LOG}
  sleep 0.5
}

update_testlog()
{
  #$1 = ${show_time}
  #$2 = ${cpu_rate}
  #$3 = {cpu_temp}
  local show_time
  local cpu_rate
  local cpu_temp

  show_time=${1}
  cpu_rate=${2}
  cpu_temp=${3}

  echo -e "${show_time}\t${cpu_rate}\t\t\t${cpu_temp}" >> ${CPU_BURN_TEST_LOG}
}

cpu_burn_display()
{
  local i j
  local pause_time=${1}
  p_bar=('/' '|' '\' '-')
  len=${#p_bar[@]}
  echo -ne "CPU_Burn "
  for (( j = 0; j < 30; j++ )); do

    for (( i = 0; i < ${len}; i++ )); do
      echo -ne "=${p_bar[$i]}="
      sleep 0.25
      echo -ne "\b\b\b"
    done
  done

  echo -ne "\b\b\b\b\b\b\b\b\b"
}

cpu_test_logfile_headergen

cpu_stress_pid=$(run_cpu_stressor)
#echo "${cpu_stress_pid}"
diff_sec=0
init_secs=$(date +'%s')

while [[ ${diff_secs} -lt ${TEST_PERIOD} ]]; do
  ps_result=$(ps -ef | grep ${cpu_stress_pid} | grep -v "grep")

  #display time , cpu rate , cpu temp , test process status

  if [[ ! -z ${ps_result} ]]; then
    show_time=$(date +'%D %T')
    cpu_rate=$(get_cpu_usage)
    cpu_temp=$(get_cpu_temp)
    echo "${show_time} : CPU Usage : ${cpu_rate}(%) PID(${cpu_stress_pid}) cpu burn is running, cpu temp : ${cpu_temp} (DegC.)"
    update_testlog "${show_time}" "${cpu_rate}" "${cpu_temp}"
    cpu_burn_display
    #cat ${CPU_BURN_TEST_LOG}
  else
    cpu_stress_pid=$(run_cpu_stressor)
    #update_testlog "${show_time}" "${cpu_rate}" "${cpu_temp}"
  fi

  cur_secs=$(date +'%s')
  diff_secs=$((${cur_secs}-${init_secs}))

done

if [[ ! -z ${ps_result} ]]; then
    kill -9 ${cpu_stress_pid}
fi
echo ""
cat ${CPU_BURN_TEST_LOG}
