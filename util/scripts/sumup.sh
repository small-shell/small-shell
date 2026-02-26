#!/bin/bash

# get data num each databox
#----------------------------------------------------------------------------------------------------
# USAGE
# countup.sh databox:$databox sumup_key:n \
# filter_key:n type:line filters:$word,$word2 frequency:daily title:$title diff:no
#----------------------------------------------------------------------------------------------------
# GRAMMER
# https://small-shell.org/python_tour/#utilscripts
#----------------------------------------------------------------------------------------------------

# load env
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env

# load param
for param in $(echo $@)
do
  if [[ $param == databox:* ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == type:* ]]; then
    type=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == sumup_key:* ]]; then
    sumup_key=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == filter_key:* ]]; then
    filter_key=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == filter:* ]]; then
    filters=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == filters:* ]]; then
    filters=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == frequency:* ]]; then
    frequency=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == gen.graph:* ]]; then
    graph=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == title:* ]]; then
    title=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == X_label:* ]]; then
    X_label=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == Y_label:* ]]; then
    Y_label=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == global_filter:* ]]; then
    global_filter=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == diff:* ]]; then
    diff=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == set_time:* ]]; then
    set_time="$(echo "$param" | cut -f 2- -d ":" | $SED "s/{####}/ /g")"
  fi

done

if [ ! "$graph" ];then
  graph="yes"
fi

if [ ! "$diff" ];then
  diff="no"
fi

if [ "$set_time" ];then
  time_value_chk=$(echo "$timestamp" | $SED "s/[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]//g")
  if [ "$time_value_chk" ];then
    echo "error: $time must be yyyy-mm-dd"
    exit 1
  fi
  timestamp="$set_time"
else
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
fi

year=$(echo "$timestamp" | $AWK -F "-" '{print $1}')
month=$(echo "$timestamp" | $AWK -F "-" '{print $2}')
day=$(echo "$timestamp" | $AWK -F "-" '{print $3}' | $AWK '{print $1}')
time=$(echo "$timestamp" | $AWK -F "-" '{print $3}' | $AWK '{print $2}')

# load authkey
. ${SCRIPT_DIR}/.authkey



WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be small-shell"
  exit 1
fi

if [ ! "$databox" ];then
  echo "error: please input databox"
  exit 1
fi

if [ ! -d ${ROOT}/databox/${databox} ];then
  echo "error: there is no databox:$databox"
  exit 1
fi

if [ "$filter_key" ];then
  key_chk=$(${ROOT}/bin/meta get.key:${databox}{all} | grep $filter_key)
  if [ ! "$key_chk" ];then
    echo "error: there is no key $filter_key"
    exit 1
  fi
fi

if [ "$sumup_key" ];then
  key_chk=$(${ROOT}/bin/meta get.key:${databox}{all} | grep $sumup_key)
  if [ ! "$key_chk" ];then
    echo "error: there is no key $sumup_key"
    exit 1
  fi
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

if [ ! "$sumup_key" ];then
  echo "error: please input sumup_key"
  exit 1
fi

# load sumup col
sumup_col=$(grep -l "name=\"${sumup_key}\"" ${ROOT}/databox/${databox}/def/* | xargs basename -a | $SED "s/col//g")
((sumup_col += 1))

if [ ! "$frequency" = "hourly" -a ! "$frequency" = "daily" -a ! "$frequency" = "monthly" -a ! "$frequency" = "snapshot" ];then
  echo "error: frequency:$frequency is wrong"
  exit 1
elif [ "$frequency" = "hourly" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/sumup_db_${databox}_${year}${month}${day}

elif [ "$frequency" = "daily" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/sumup_db_${databox}_${year}${month}

elif [ "$frequency" = "monthly" ];then
  output=${SCRIPT_DIR}/../statistics/rawdata/sumup_db_${databox}_${year}

elif [ "$frequency" = "snapshot" ];then
   output=${SCRIPT_DIR}/../statistics/rawdata/sumup_db_${databox}_s_${year}${month}${day}
  if [ -f "${output}.csv" ];then
    rm ${output}.csv
  fi
fi


# adjust ouput file name

if [ "$title" ];then
  output_title=$(echo "$title" | $SED "s/{####}/_/g" | $SED "s/!//g" | $SED "s/\$//g" | $SED "s/\///g" | $SED "s/\&//g" | $SED "s/://g")
  output="${output}{$title}_sumupkey{$sumup_key}"

  if [ "$filters" -o "$filter_key" ];then
    output="${output}_filterkey{$filter_key}"

    if [ ! "$filter_key" -o ! "$filters" ];then
      echo "please define filter_key and filter words"
      exit 1
    fi
  fi
else
  if [ "$filters" -o "$filter_key" ];then
    output="${output}_sumkey{$sumup_key}_filterkey{$filter_key}"
    if [ ! "$filter_key" -o ! "$filters" ];then
      echo "please define filter_key and filter words"
      exit 1
    fi
  fi
fi


if [ "$filter_key" -a "$filters" ];then

  if [ ! -f ${output}.csv ];then
    echo "Time,$filters" > $output.csv
  else
    org_column=$(head -1 $output.csv | $SED -z "s/,/\n/g" | wc -l | tr -d " ")
    filter_num=$(echo "$filters" | $SED -z "s/,/\n/g" | wc -l | tr -d " ")
    (( filter_num +=1 ))
    if [ ! $org_column -eq $filter_num ];then
      echo "error: Number of filter has been changed, please delete $output.csv first"
      exit 1
    fi
  fi

  sumups=""
  for filter in $(echo "$filters" | $SED -s "s/,/ /g")
  do
    sumup=0
    tmp=${SCRIPT_DIR}/tmp/exec.$(date +%s).$RANDOM

    filter_chmeta=$(echo "$filter" \
    | $SED "s/}//g" | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | $SED "s/_/{%%%%%%%}/g" | $SED "s/\//{%%%%%}/g"  \
    | $SED "s/(/{%%%%%%%%}/g" | $SED "s/)/{%%%%%%%%%}/g" | $SED "s/\[/{%%%%%%%%%%}/g" | $SED "s/\]/{%%%%%%%%%%%}/g" \
    | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" | $SED "s/*/{%%%%%%%%%%%%%%%}/g" | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | $SED "s/,/{%%%%%%}/g"  | $SED "s/#/{%%%%%%%%%%%%%}/g" |  $SED "s/\&/{%%%%}/g" | $SED "s/:/{%%%}/g")

    if [ "$global_filter" ];then
      global_filter_chmeta=$(echo "$global_filter" \
      | $SED "s/}//g" | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
      | $SED "s/_/{%%%%%%%}/g" | $SED "s/\//{%%%%%}/g"  \
      | $SED "s/(/{%%%%%%%%}/g" | $SED "s/)/{%%%%%%%%%}/g" | $SED "s/\[/{%%%%%%%%%%}/g" | $SED "s/\]/{%%%%%%%%%%%}/g" \
      | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" | $SED "s/*/{%%%%%%%%%%%%%%%}/g" | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
      | $SED "s/,/{%%%%%%}/g"  | $SED "s/#/{%%%%%%%%%%%%%}/g" |  $SED "s/\&/{%%%%}/g" | $SED "s/:/{%%%}/g")

      echo "${ROOT}/bin/DATA_shell databox:$databox authkey:$authkey \
      command:show_all[filter=${filter_key}{${filter_chmeta}}] format:none | grep $global_filter_chmeta |  $SED -r \"s/^::::::(.*):::::://g\" \
      | $AWK -F \",\" '{print \$$sumup_col}'| $SED \"s/-/0/g\" | $SED -z \"s/\n/ + /g\" | $SED \"s/+ $//g\""\
      > $tmp
    else
      echo "${ROOT}/bin/DATA_shell databox:$databox authkey:$authkey \
      command:show_all[filter=${filter_key}{${filter_chmeta}}] format:none | $SED -r \"s/^::::::(.*):::::://g\" \
      | $AWK -F \",\" '{print \$$sumup_col}'| $SED \"s/-/0/g\" | $SED -z \"s/\n/ + /g\" | $SED \"s/+ $//g\""\
      > $tmp
    fi
   
    # access to DATTA_shell and get numbers with + 
    chmod 755 $tmp
    $tmp > $tmp.result

    if [ ! -s $tmp.result ];then
      echo 0 > $tmp.result
    fi

    input_chk=$(cat $tmp.result | $SED "s/[0-9]//g" | $SED "s/+//g" | $SED "s/ //g")
    if [ "$input_chk" ];then  
      echo "error: sumup failed. it seems key:$sumup_key contain text character."
      rm -rf $tmp*
      exit 1
    fi
   
    grep + $tmp.result  >/dev/null 2>&1
    if [ $? -eq 0 ];then
      sumup="expr $(cat $tmp.result)"
      sumup=$(eval $sumup)
    else
      sumup=$(cat $tmp.result | $SED "s/ //g")
    fi

    if [ ! "$sumup" ];then
      sumup=0
    fi

    numeric_chk=$(echo "$sumup" | $SED "s/[0-9]//g")
    if [ "$numeric_chk" ];then
      echo "error: sumup key's column must be numeric character only"
      rm -rf $tmp*
      exit 1
    fi

    if [ "$diff" = "yes" ];then
      history="${SCRIPT_DIR}/tmp/.${databox}_${filter}_${filter_key}_${sumup_key}_sumup"
      if [ -f $history ];then 
        lastnum=$(cat $history)
        echo "$sumup" > $history
        sumup=$(expr $sumup - $lastnum)
      else
        echo "$sumup" > $history
      fi
    fi

    if [ "$sumups" ];then
      sumups="$sumups,$sumup"
    else
      sumups=$sumup
    fi
    rm -rf $tmp*
 
  done
  echo "$timestamp,$sumups" >> $output.csv

else
# else means no filters

  tmp=${SCRIPT_DIR}/tmp/exec.$(date +%s).$RANDOM

  if [ "$global_filter" ];then
    echo "${ROOT}/bin/DATA_shell databox:$databox authkey:$authkey \
    command:show_all format:none | grep $global_filter | $SED -r \"s/^::::::(.*):::::://g\" \
    | $AWK -F \",\" '{print \$$sumup_col}'| $SED \"s/-/0/g\" | $SED -z \"s/\n/ + /g\" | $SED \"s/+ $//g\""\
    > $tmp
  else
    echo "${ROOT}/bin/DATA_shell databox:$databox authkey:$authkey \
    command:show_all format:none | $SED -r \"s/^::::::(.*):::::://g\" \
    | $AWK -F \",\" '{print \$$sumup_col}'| $SED \"s/-/0/g\" | $SED -z \"s/\n/ + /g\" | $SED \"s/+ $//g\""\
    > $tmp
  fi
 
  chmod 755 $tmp
  $tmp > $tmp.result

  if [ ! -s $tmp.result ];then
    echo 0 > $tmp.result
  fi

  input_chk=$(cat $tmp.result | $SED "s/[0-9]//g" | $SED "s/+//g" | $SED "s/ //g")
  if [ "$input_chk" ];then  
    echo "error: sumup failed. it seems key:$sumup_key contain text character."
    rm -rf $tmp*
    exit 1
  fi

  grep + $tmp.result  >/dev/null 2>&1
  if [ $? -eq 0 ];then
    sumup="expr $(cat $tmp.result)"
    sumup=$(eval $sumup)
  else
    sumup=$(cat $tmp.result | $SED "s/ //g")
  fi

  if [ ! -f ${output}.csv ];then
    echo "Time,Total" > $output.csv
  fi

  if [ "$diff" = "yes" ];then
    history="${SCRIPT_DIR}/tmp/.${databox}_${sumup_key}_sumup"
    if [ -f $history ];then
      lastnum=$(cat $history)
      echo "$sumup" > $history
      sumup=$(expr $sumup - $lastnum)
    else
      echo "$sumup" > $history
    fi
  fi

  echo "$timestamp,$sumup" >> $output.csv
  rm -rf $tmp*

fi

if [ "$type" = "line" ];then
  line_chk=$(cat $output.csv | wc -l | tr -d " ")
  if [ $line_chk -le 2 ];then
    echo "warn: you can't generate line graph for only 1 time snapshot, type has been chaned to bar"
    type=bar
  fi
fi

# Generate graph using pyshel
if [ "$graph" = "yes" ];then
  titlestamp=$(echo "$timestamp" | $SED "s/ /{####}/g" | $SED "s/:/{#####}/g")

  if [ ! "$title" ];then
    case "$frequency" in
      "monthly" ) title="title:$databox.monthly.stats" ;;
      "daily" )  title="title:$databox.daily.stats" ;;
      "hourly" ) title="title:$databox.hourly.stats" ;;
      "snapshot" ) title="title:$databox.${titlestamp}{####}snapshot" ;;
    esac
  else
    title="title:$title"
  fi

  if [ ! "$X_label" ];then
    if [ ! "$frequency" = "snapshot" ];then
      case "$frequency" in
        "monthly" ) X_label="X_label:${year}" ;;
        "daily" ) X_label="X_label:${year}-${month}" ;;
        "hourly" ) X_label="X_label:${year}-${month}-${day}" ;;
      esac
    else
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
    ${ROOT}/util/pyshell/pygraph.sh type:$type,$frequency input:$output.csv \
    output:${ROOT}/util/statistics/graph/$(echo "$output" | xargs basename -a).png \
    $title $X_label $Y_label
  else
    ${ROOT}/util/pyshell/pygraph.sh type:$type,snapshot{$timestamp} input:$output.csv \
    output:${ROOT}/util/statistics/graph/$(echo "$output" | xargs basename -a).png \
    $title $X_label $Y_label
  fi

fi

# sync to replica hosts
. ${ROOT}/web/base
if [ "$cluster_server" ];then
  if [ ! "$master" ];then
    for replica in $replica_hosts
    do
      scp -i /home/small-shell/.ssh/id_rsa ${ROOT}/util/statistics/graph/* small-shell@${replica}:${ROOT}/util/statistics/graph/
      scp -i /home/small-shell/.ssh/id_rsa ${ROOT}/util/statistics/rawdata/* small-shell@${replica}:${ROOT}/util/statistics/rawdata/
    done
  fi
fi

