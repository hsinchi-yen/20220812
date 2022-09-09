#!/bin/bash


#check if vlc available
vpu_play_chk()
{
  local vlc_utility

  vlc_utility="/usr/bin/vlc"
  if [[ -f ${vlc_utility} ]]; then
    echo "VLC Utility is existed"
    return 0
  else
    echo "VLC Utility is not available, please install"
    return 1
  fi
}
#check if video files availables

video_files_chk()
{
  local ls_result
  ls_result=$(ls ./ | grep -E "MP4|AVI|WMV|WebM")

  if [[ ! -z ${ls_result} ]]; then
    echo "Video files are loaded"
    return 0
  else
    echo "Video files are not loaded, please check!"
    return 1
  fi
}
declare -A video_fmt_arr=(\
[H264]="big_buck_bunny_1080p_H264_AAC_25fps_7200K.MP4" \
[MPEG4]="big_buck_bunny_1080p_MPEG4_MP3_25fps_7600K.AVI" \
[VC1]="big_buck_bunny_1080p_VC1_WMA3_25fps_8600K.WMV" \
[VP8]="big_buck_bunny_1080p_VP8_VORBIS_25fps_7800K.WebM" \
)

vpu_play_chk
vpu_play_chk_ret=$?
video_files_chk
video_files_chk_ret=$?

#start to play

if [ ${vpu_play_chk_ret} -eq 1 ] && [ ${video_files_chk_ret} -eq 1 ]; then
  echo "required files is not available"
else
  echo "VPU decode test start ... "

  for key in "${!video_fmt_arr[@]}";do
    echo "VPU decode : ${key}, file:${video_fmt_arr[${key}]}"
    mpv "${video_fmt_arr[${key}]}"
    decode_result=$?

    if [[ ${decode_result} -ne 0 ]]; then
      echo "${key} decode test : FAIL"
    else
      echo "${key} decode test : PASS"
    fi
  done


fi
