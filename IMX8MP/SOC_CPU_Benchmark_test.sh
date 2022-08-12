: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Test CPU performance with sysbench utility
 Script name       : SOC_CPU_Benchmark_test.sh
 Author            : lancey
 Date created      : 20220812
 Applied platform  : Yocto 3.3 / imx8mp
-----------------------------------------------------------------------
 Revision History  :
 Date        Author      Ref    Revision (Date in YYYYMMDD format)
-----------------------------------------------------------------------
 20220809    lancey      1      Initial draft for test
************************************************************************
'

#!/bin/bash

CPU_BenchTESTLOG=/tmp/CPUbenchmark.txt
# Check CPU processors

run_cpu_benchmark()
{
  sysbench --test=cpu --num-threads=$1 --cpu-max-prime=100000 run
}


is_Sysbench()
{
  #check if sysbench's existence
  test -f /usr/bin/sysbench
  result=$?
  echo "${result}"
  if [[ "${result}" -eq 0 ]]; then
    return 0
  else
    echo "/usr/bin/sysbench is unavailable , please consult SW RD for this issue"
    return 1
  fi
}

#get the cpu's core'qty
CPUS=$(grep "processor" /proc/cpuinfo | wc -l)

clear
{
is_Sysbench
filechk=$?

if [[ $filechk -eq 1 ]]; then
    :
else
    echo "***** Sysbench Test Start *****"
    echo "***** CPU Benchmark - Single"
    run_cpu_benchmark 1

    #echo $CPUS
    wait $!
    echo "***** Sysbench Test Start *****"
    echo "***** CPU Benchmark - MultiCore:$CPUS"
    run_cpu_benchmark ${CPUS}
    sleep 1&
    wait $!

fi

#redirect test output to /tmp/logfiles
} | tee -a ${CPU_BenchTESTLOG}
