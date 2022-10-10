#!/bin/bash

: '
Script name : memtester_stress_test.sh
Purpose : use test utility to run memory stresstest and generate testlog

-------------------------------------------------------------
date        author          Note
-------------------------------------------------------------
20221009    lancey          intitial draft
-------------------------------------------------------------
'
TEST_PERIOD=3600
MEMTESTER_TEST_LOG=/tmp/memtester_testlog.txt
MEMTESTER_TEMP_LOG='./memtester_tmp.txt'

run_memtester()
{
  local memtester_pid
  memtester "100M 1" > ${MEMTESTER_TEMP_LOG}&
  memtester_pid=$!
  echo "${memtester_pid}"
}

get_cpu_usage()
{
  local cpu_rate
  #first way for get cpu usage
  cpu_rate=$(top -n 1 -b | awk '/^%Cpu/{print $2}')
  #second way for get cpu usage
  #cpu_rate=$(top -bn1 | grep "stress" | head -1 | awk -F ' ' '{print $9}')
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

mem_test_logfile_headergen()
{
  if [[ -f ${MEMTESTER_TEST_LOG} ]]; then
    rm -f ${MEMTESTER_TEST_LOG}
  fi
  touch ${MEMTESTER_TEST_LOG}
  echo -e "TIME\t\t\tCPUrate\t\tCPU_TEMP\t\tMEM_TEST_RESULT" >> ${MEMTESTER_TEST_LOG}
  echo -e "==============================================================================="  >> ${MEMTESTER_TEST_LOG}
}

update_testlog()
{
  #$1 = ${show_time}
  #$2 = ${cpu_rate}
  #$3 = {cpu_temp}
  local show_time
  local cpu_rate
  local cpu_temp
  local mem_result

  show_time=${1}
  cpu_rate=${2}
  cpu_temp=${3}
  mem_result=${4}

  echo -e "${show_time}\t${cpu_rate}\t\t${cpu_temp}\t\t${mem_result}" >> ${MEMTESTER_TEST_LOG}
}

mem_burn_display()
{
  local i j
  local pause_time=${1}
  p_bar=('/' '|' '\' '-')
  len=${#p_bar[@]}
  echo -ne "Memtester ... Running"
  for (( j = 0; j < ${pause_time}; j++ )); do

    for (( i = 0; i < ${len}; i++ )); do
      echo -ne "=${p_bar[$i]}="
      sleep 0.025
      echo -ne "\b\b\b"
    done
  done

  echo -ne "\b\b\b\b\b"
}

get_all_mem()
{
  local size_all_mem
  size_all_mem=$(free -h | grep Mem: | awk -F ' ' '{print $2}')
  echo ${size_all_mem}
}

get_used_mem()
{
  local size_used_mem
  size_used_mem=$(free -h | grep Mem: | awk -F ' ' '{print $3}')
  echo ${size_used_mem}
}

get_free_mem()
{
  local size_free_mem
  size_free_mem=$(free -h | grep Mem: | awk -F ' ' '{print $4}')
  echo ${size_free_mem}
}

get_memtester_result()
{
  local memtester_result
  local ok_count
  ok_count=$(cat ${MEM_TEST_TEMP_LOG} | grep "ok" | wc -l)

  if [[ ${ok_count} -eq 18 ]]; then
    memtester_result="PASS"
  else
    memtester_result="FAIL"
  fi

  echo "${memtester_result}"

}

mem_test_logfile_headergen

size_all_mem=$(get_all_mem)

mem_stress_pid=$(run_memtester)
#echo "${cpu_stress_pid}"
diff_sec=0
init_secs=$(date +'%s')

while [[ ${diff_secs} -lt ${TEST_PERIOD} ]]; do
  ps_result=$(ps -ef | grep ${mem_stress_pid} | grep -v "grep")

  #display time , cpu rate , cpu temp , test process status

  if [[ ! -z ${ps_result} ]]; then
    show_time=$(date +'%D %T')
    cpu_rate=$(get_cpu_usage)
    cpu_temp=$(get_cpu_temp)
    used_mem=$(get_used_mem)
    free_mem=$(get_free_mem)

    echo "${show_time} : PID(${mem_stress_pid}) Memory Burn is running ..."
    echo "CPU Usage : ${cpu_rate}(%), cpu temp : ${cpu_temp} (DegC.)"
    echo "total mem : ${size_all_mem}, used mem : ${used_mem}, free mem : ${free_mem}"

    #update_testlog "${show_time}" "${cpu_rate}" "${cpu_temp}"
    mem_burn_display 600
    #sleep 3
  else
    mem_test_result=$(get_memtester_result)
    echo ""
    cat ${MEMTESTER_TEMP_LOG}
    echo "Memory memtester result : ${mem_test_result}"
    update_testlog "${show_time}" "${cpu_rate}" "${cpu_temp}" "${mem_test_result}"
    mem_stress_pid=$(run_memtester)
    #update_testlog "${show_time}" "${cpu_rate}" "${cpu_temp}"
  fi

  cur_secs=$(date +'%s')
  diff_secs=$((${cur_secs}-${init_secs}))

done

if [[ ! -z ${ps_result} ]]; then
    kill -9 ${mem_stress_pid}
fi
echo ""
cat ${MEMTESTER_TEST_LOG}
