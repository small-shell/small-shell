#!/bin/bash

# load query string param
for param in `echo $@`
do

  if [[ $param == target:* ]]; then
    target=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == type:* ]]; then
    type=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ "$target" = "" -a ! "$type" ];then
  echo "error: please set target data name and data type"
  exit 1
fi

if [ ! -d ../tmp/${session}_statistics ];then
  mkdir ../tmp/${session}_statistics
fi

# -----------------
# Exec command
# -----------------

if [ "$type" = "rawdata" ];then

  echo "Content-Type: text/html"
  echo ""

  # gen %%statistics contents
  sudo -u small-shell ${small_shell_path}/bin/meta  get.statistics:${target}{rawdata} \
  > ../tmp/${session}_statistics/result

  # render HTML
  cat ../descriptor/statistics_viewer.html.def | sed "s/^ *</</g" \
  | sed "/%%statistics/r ../tmp/${session}_statistics/result" \
  | sed "s/%%statistics//g"\
  | sed "s/%%target/$target/g"

elif [ "$type" = "graph" ];then
  echo "Content-Type: image/png"
  echo ""
  # render graph 
  sudo -u small-shell ${small_shell_path}/bin/meta  get.statistics:${target}{graph} 
fi

if [ "$session" ];then
  rm -rf ../tmp/${session}_statistics
fi

exit 0
