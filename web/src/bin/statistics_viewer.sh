#!/bin/bash

# load small-shell conf
. %%www/def/.small_shell_conf

# load small-shell conf
. %%www/def/.small_shell_conf

# load query string param
for param in $(echo $@)
do

  if [[ $param == target:* ]]; then
    target=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == type:* ]]; then
    type=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == session:* ]]; then
    session=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done

if [ "$target" = "" -a ! "$type" ];then
  echo "error: please set target data name and data type"
  exit 1
fi

if [ ! -d %%www/tmp/${session}_statistics ];then
  mkdir %%www/tmp/${session}_statistics
fi

# -----------------
# Exec command
# -----------------

if [ "$type" = "rawdata" ];then

  echo "Content-Type: text/html"
  echo ""

  # gen %%statistics contents
  ${small_shell_path}/bin/meta  get.statistics:${target}{rawdata} \
  > %%www/tmp/${session}_statistics/result

  # render HTML
  cat %%www/def/statistics_viewer.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%statistics/r %%www/tmp/${session}_statistics/result" \
  | $SED "s/%%statistics//g"\
  | $SED "s/%%target/${target}/g"

elif [ "$type" = "graph" ];then
  echo "Content-Type: image/png"
  echo ""
  # render graph 
  ${small_shell_path}/bin/meta  get.statistics:${target}{graph} 
fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}_statistics
fi

exit 0
