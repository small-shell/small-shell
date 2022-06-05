#!/bin/bash

# get data num each databox
#----------------------------------------------------------------------------------------------------
# USAGE
# countup.sh databox:$databox type:line key:$key filters:$word1,$word2 frequcney:daily \
# title:$title X_label:$xlabel Y_label:$ylabel global_filter:$word diff:no
#----------------------------------------------------------------------------------------------------
# GRAMMER
# https://small-shell.org/python_tour/#utilscripts
#----------------------------------------------------------------------------------------------------

# load param
for param in `echo $@`
do
  if [[ $param == databox:* ]]; then
    databox=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == type:* ]]; then
    type=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == key:* ]]; then
    key=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == filter_key:* ]]; then
    key=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == filter:* ]]; then
    filters=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == filters:* ]]; then
    filters=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == frequency:* ]]; then
    frequency=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == gen.graph:* ]]; then
    graph=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == title:* ]]; then
    title=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == X_label:* ]]; then
    X_label=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == Y_label:* ]]; then
    Y_label=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == global_filter:* ]]; then
    global_filter=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == diff:* ]]; then
    diff=`echo $param | awk -F":" '{print $2}'`
  fi

done

if [ ! "$graph" ];then
  graph="yes"
fi

if [ ! "$diff" ];then
  diff="no"
fi

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

# load authkey
. ${SCRIPT_DIR}/.authkey

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be small-shell"
  exit 1
fi

if [ ! "$databox" ];then
  echo "error: please input databox"
  exit 1
fi

if [ ! -d $ROOT/databox/$databox ];then
  echo "error: databox:$databox is wrong"
  exit 1
fi

if [ ! "$type" ];then
   type=line
fi

if [ ! "$type" = "line" -a ! "$type" = "bar" -a ! "$type" = "pie" ];then
  echo "error: type is wrong, please use line or bar or pie"
  exit 1
fi

if [ ! "$frequency" ];then
  frequency=daily
fi

if [ ! "$frequency" = "hourly" -a ! "$frequency" = "daily" -a ! "$frequency" = "monthly" -a ! "$frequency" = "snapshot" ];then
  echo "error: frequency:$frequency is wrong"
  exit 1
elif [ "$frequency" = "hourly" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/countup_d_`date +%Y%m%d`_db_${databox}

elif [ "$frequency" = "daily" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/countup_m_`date +%Y%m`_db_${databox}

elif [ "$frequency" = "monthly" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/countup_y_`date +%Y`_db_${databox}

elif [ "$frequency" = "snapshot" ];then
  
  if [ ! "$type" = "line" ];then
    output=${SCRIPT_DIR}/../statistics/rawdata/countup_s_`date +%Y%m%d`_db_${databox}
  else
    frequency=daily
    output=${SCRIPT_DIR}/../statistics/rawdata/countup_m_`date +%Y%m`_db_${databox}
  fi

fi

timestamp=`date "+%Y-%m-%d %H:%M:%S"`

# adjust ouput file name

if [ "$title" ];then
  output_title=`echo $title | sed "s/{####}/_/g" | sed "s/!//g" | sed "s/\$//g" | sed "s/\///g" | sed "s/\&//g" | sed "s/://g"`
  output="${output}{$output_title}" 
  if [ "$filters" -o "$key" ];then
    output="${output}${key}_filtered"
    if [ ! "$key" -o ! "$filters" ];then
      echo "please define filter and key"
      exit 1
    fi
  fi
else
  if [ "$filters" -o "$key" ];then
    output="${output}_${key}_filtered"
    if [ ! "$key" -o ! "$filters" ];then
      echo "please define filter and key"
      exit 1
    fi
  fi
fi

# Countup number

if [ "$key" -a "$filters" ];then

  if [ ! -f ${output}.csv ];then
    echo "Time,$filters" > $output.csv
  else
    org_column=`head -1 $output.csv | sed -z "s/,/\n/g" | wc -l` 
    filter_num=`echo $filters | sed -z "s/,/\n/g" | wc -l`
    (( filter_num +=1 ))
    if [ ! $org_column -eq $filter_num ];then
      echo "error: Number of filter has been changed, please delete $output.csv first"
      exit 1
    fi
  fi

  countups=""
  for filter in `echo $filters | sed -s "s/,/ /g"`
  do
    countup=0

    filter_chmeta=`echo $filter \
    | sed "s/}//g" | sed "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | sed "s/_/{%%%%%%%}/g" | sed "s/\//{%%%%%}/g"  \
    | sed "s/(/{%%%%%%%%}/g" | sed "s/)/{%%%%%%%%%}/g" | sed "s/\[/{%%%%%%%%%%}/g" | sed "s/\]/{%%%%%%%%%%%}/g" \
    | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" | sed "s/*/{%%%%%%%%%%%%%%%}/g" | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | sed "s/,/{%%%%%%}/g"  | sed "s/#/{%%%%%%%%%%%%%}/g" |  sed "s/\&/{%%%%}/g" | sed "s/:/{%%%}/g"`
    
    if [ "$global_filter" ];then
      global_filter_chmeta=`echo $global_filter \
      | sed "s/}//g" | sed "s/%/{%%%%%%%%%%%%%%%%}/g"\
      | sed "s/_/{%%%%%%%}/g" | sed "s/\//{%%%%%}/g"  \
      | sed "s/(/{%%%%%%%%}/g" | sed "s/)/{%%%%%%%%%}/g" | sed "s/\[/{%%%%%%%%%%}/g" | sed "s/\]/{%%%%%%%%%%%}/g" \
      | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" | sed "s/*/{%%%%%%%%%%%%%%%}/g" | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
      | sed "s/,/{%%%%%%}/g"  | sed "s/#/{%%%%%%%%%%%%%}/g" |  sed "s/\&/{%%%%}/g" | sed "s/:/{%%%}/g"`
      countup=`$ROOT/bin/DATA_shell databox:$databox authkey:$authkey \
      command:show_all[filter=$key{${filter_chmeata}}] format:none | grep $global_filter_chmeta | wc -l` 
    else
      countup=`$ROOT/bin/DATA_shell databox:$databox authkey:$authkey \
      command:show_all[filter=$key{${filter_chmeta}}] format:none | wc -l` 
    fi

    if [ "$diff" = "yes" ];then
      history="${SCRIPT_DIR}/tmp/.${databox}_${filter}_${key}_countup"
      if [ -f $history ];then
        lastnum=`cat $history`
        echo $countup  > $history
        countup=`expr $countup - $lastnum`
      else
        echo $countup > $history
      fi
    fi
  
    if [ "$countups" ];then
      countups="$countups,$countup"
    else
      countups=$countup
    fi
  done


  echo "$timestamp,$countups" >> $output.csv

else
  # else means no filters

  if [ "$global_filter" ];then
    countup=`$ROOT/bin/DATA_shell databox:$databox authkey:$authkey \
    command:show_all format:none | grep $global_filter_chmeta | wc -l` 
  else
    countup=`$ROOT/bin/meta get.num:$databox` 
  fi

  if [ "$diff" = "yes" ];then
    history="${SCRIPT_DIR}/tmp/.${databox}_countup"
    if [ -f $history ];then
      lastnum=`cat $history`
      echo $countup  > $history
      countup=`expr $countup - $lastnum`
    else
      echo $countup > $history
    fi
  fi
  
  if [ ! -f ${output}.csv ];then
    echo "Time,total" > $output.csv
  fi
  echo "$timestamp,$countup" >> $output.csv

fi

if [ "$type" = "line" ];then
  line_chk=`cat $output.csv | wc -l`
  if [ $line_chk -le 2  ];then
    echo "warn: you can't generate line graph only 1 time snapshot, it will be chaned to bar"
    type=bar
  fi
fi

# Generate graph using pyshel
if [ "$graph" = "yes" ];then

  if [ ! "$title" ];then
    case "$frequency" in
      "monthly" ) title="title:`date +%Y-%m`{####}db_$databox.data" ;;
      "daily" )  title="title:`date +%Y-%m`{####}db_$databox" ;;
      "hourly" ) title="title:`date +%Y-%m-%d`{####}db_$databox" ;;
      "snapshot" ) title="title:db_$databox" ;;
    esac
  else
    title="title:$title"
  fi

  if [ ! "$X_label" ];then
    if [ ! "$frequency" = "snapshot" ];then
      X_label="X_label:${frequency}.stats"
    else
      titlestamp=`echo $timestamp | sed "s/ /{####}/g" | sed "s/:/{#####}/g"`
      X_label="X_label:snapshot.$titlestamp"
    fi
  else
    X_label="X_label:$X_label"
  fi

  if [ ! "$Y_label" ];then
    Y_label=""
  else
    Y_label="Y_label:$Y_label"
  fi

  # GEN GRAPH
  if [ "$type" = "pie" -a ! "$frequency" = "snapshot" ];then
    echo "warn: frequency must be snapshot for pie graph"
    frequency="snapshot"
  fi
  
  if [ ! "$frequency" = "snapshot" ];then
    $ROOT/util/pyshell/pygraph.sh type:$type,$frequency input:$output.csv \
    output:$ROOT/util/statistics/graph/`echo $output | xargs basename -a`.png \
    $title $X_label $Y_label
  else
    $ROOT/util/pyshell/pygraph.sh type:$type,snapshot{$timestamp} input:$output.csv \
    output:$ROOT/util/statistics/graph/`echo $output | xargs basename -a`.png \
    $title $X_label $Y_label
  fi

fi

