: '
************************************************************************
 Project           : SIT team Test script for Yocto
 Purpose           : Test GPU performance with built-in utility.
 Script name       : SOC_GPU_test.sh
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

#!/bin/bash

GPU_LOFILE='/tmp/gpu_testlog.txt'
GPU_Scenes='glmark2-es2-wayland -l'
GPU_Test='glmark2-es2-wayland --fullscreen --annotate'

echo "GPU Test Start ..."
$GPU_Scenes | tee $GPU_LOFILE

echo "------------------------------------------------------------" | tee -a $GPU_LOFILE
echo ""

$GPU_Test | tee -a $GPU_LOFILE
sleep 0.5

GPU_score=$(cat $GPU_LOFILE | grep "glmark2 Score:" | \
awk -F ':' '{print $2}' | sed 's/ //g')

echo
echo "GPU Benchmark result : $GPU_score"
fbset -i | tee -a $GPU_LOFILE
