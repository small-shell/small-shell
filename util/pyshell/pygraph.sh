#!/bin/bash

#--------------------------------------------------------------
# usage: pygraph.sh type:$type input:$input output:$output \
#        title:$title X_label:$X_label Y_label:$Y_label
#--------------------------------------------------------------

# graph types
#--------------------------------------------------------------
# type:bar,hourly
# type:bar,daily
# type:bar,monthly
# type:line,hourly 
# type:line,daily 
# type:line,monthly
# type:pie,snapshot{yyyy-mm-dd HH:MM}
# type:bar,snapshot{yyyy-mm-dd HH:MM}
#--------------------------------------------------------------

SCRIPT_DIR=$(dirname $0)

# load gloibal env
. ${SCRIPT_DIR}/../../.env

# load pyshel env
. ${SCRIPT_DIR}/pyenv

if [  ! -x $PYTHON ];then
  echo "please define executable path of python on ${SCRIPT_DIR}/pyenv if you want to gen graph"
  exit 1
fi

# load param
for param in $(echo $@)
do
  if [[ $param == type:* ]]; then
    type=$(echo "$param" | $AWK -F":" '{print $2}' | $AWK -F "," '{print $1}')
    timeline="$(echo "$param" | $AWK -F":" '{print $2}' | $AWK -F "," '{print $2}')"
  fi

  if [[ $param == input:* ]]; then
    input=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == output:* ]]; then
    output=$(echo "$param" | $AWK -F":" '{print $2}')
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
done

if [ ! "$type" ];then
  echo "error: please input graph type"
  exit 1
fi

if [ ! "$timeline" ];then
  echo "error: please input graph type with timeline,like type:bar,hourly"
  exit 1
fi

if [ ! "$input" ];then
  echo "error: please define input csv file"
  exit 1
fi

if [ ! "$output" ];then
  output=${ROOT}/util/statistics/graph/$(date +%Y%m%d).png
fi

if [[ ! $output == *.png ]]; then
  echo "output file must be \${PATH}/\${name}.png"
  exit 1
fi

function time_fmt_chk(){
  fmt_chk=$(cat $input | head -1 | $AWK -F "," '{print $1}') 
  if [ ! "$fmt_chk" = "Time" ];then
    echo "CSV format must be started from \"Time\""
    echo "e.g."
    echo "------------------------------------------"
    echo "Time,label1,label2"
    echo "2021-01-01 01:00:00,1,2"
    echo "2021-01-01 02:00:00,1,2"
    echo "------------------------------------------"
    exit 1
  fi
}

pyexe=${SCRIPT_DIR}/pyexe/exec.$(date +%s).$RANDOM
pyexe_org=$pyexe

tmpcsv=${SCRIPT_DIR}/pyexe/csv.$(date +%s).$RANDOM
tmpcsv_org=$tmpcsv


if [ "$type" = "line" -o "$type" = "bar" ]; then
 
  case "$timeline" in

  "hourly" )
    time_fmt_chk

    # gen pyexe with changing time format,remove yyyy-mm-dd and sec
    cat $input | $SED -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" | $SED -r "s/:([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_${type}_plot.py | $SED "s#%%output#${output}#g" | $SED "s#%%csv#${input}#g" | $SED "s#%%font_family#${font_family}#g" \
    | $SED "s#%%index#Time#g" | $SED "s#%%legend#True#g" > $pyexe ;;

  "daily" )
    time_fmt_chk

    # gen pyexe with changing time format,remove Year and HH:MM and sec
    cat $input | $SED -r "s/^([0-9]*)-//g" | $SED -r "s/ ([0-9]*):([0-9]*):([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_${type}_plot.py | $SED "s#%%output#${output}#g" | $SED "s#%%csv#${input}#g" | $SED "s#%%font_family#${font_family}#g" \
    | $SED "s#%%index#Time#g" | $SED "s#%%legend#True#g"  > $pyexe ;;

  "monthly" )
    time_fmt_chk

    # gen pyexe with changing time format,remove Year and HH:MM
    cat $input | $SED -r "s/^([0-9]*)-//g" | $SED -r "s/ ([0-9]*):([0-9]*):([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_${type}_plot.py | $SED "s#%%output#${output}#g" | $SED "s#%%csv#${input}#g" | $SED "s#%%font_family#${font_family}#g" \
    | $SED "s#%%index#Time#g" | $SED "s#%%legend#True#g"  > $pyexe ;;

  snapshot* )
    cat $input | head -1 | $SED "s/Time,//g" | $SED "s/,/\n/g" > $tmpcsv.items
    time=$(echo "$timeline" | $AWK -F "{" '{print $2}' | $SED "s/}//g")
    grep "$time" $input | $SED -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" \
    | $SED -r "s/([0-9]*):([0-9]*):([0-9]*),//g" | $SED "s/,/\n/g" > $tmpcsv.nums

    # gen python list
    labels=$(cat $tmpcsv.items | $SED "s/^/\'/g" | $SED "s/$/\'/g" | $SED -z "s/\n/,/g" | $SED "s/,$//g" )
    datas=$(cat $tmpcsv.nums | $SED -z "s/\n/,/g" | $SED "s/,$//g" )

    cat ${SCRIPT_DIR}/lib/pyplot_bar_snap.py | $SED "s#%%output#${output}#g" | $SED "s#%%labels#${labels}#g" | $SED "s#%%datas#${datas}#g" \
    | $SED "s#%%font_family#$font_family#g" > $pyexe ;;
    
  esac

  if [ "$title" ];then
    title=$(echo "$title" | $SED "s/{####}/ /g" | $SED "s/{#####}/:/g")
    cat $pyexe | $SED "s/%%title/${title}/g" > $pyexe.title
    pyexe=$pyexe.title
  else
    cat $pyexe | $SED -r "s/(.*)%%title(.*)//g" > $pyexe.title
    pyexe=$pyexe.title
  fi

  if [ "$X_label" ];then
    X_label=$(echo "$X_label" | $SED "s/{####}/ /g" | $SED "s/{#####}/:/g")
    cat $pyexe | $SED "s/%%X_label/${X_label}/g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  else
    cat $pyexe | $SED -r "s/(.*)%%X_label(.*)//g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  fi

  if [ "$Y_label" ];then
    Y_label=$(echo "$Y_label" | $SED "s/{####}/ /g" | $SED "s/{#####}/:/g")
    cat $pyexe | $SED "s/%%Y_label/${Y_label}/g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  else
    cat $pyexe | $SED -r "s/(.*)%%Y_label(.*)//g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  fi

fi

if [ "$type" = "pie" ];then

  if [[ $timeline == snapshot* ]]; then
    cat $input | head -1 | $SED "s/Time,//g" | $SED "s/,/\n/g" > $tmpcsv.items
    time=$(echo "$timeline" | $AWK -F "{" '{print $2}' | $SED "s/}//g")
    grep "$time" $input | $SED -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" \
    | $SED -r "s/([0-9]*):([0-9]*):([0-9]*),//g" | $SED "s/,/\n/g" > $tmpcsv.nums

    # gen python list
    labels=$(cat $tmpcsv.items | $SED "s/^/\'/g" | $SED "s/$/\'/g" | $SED -z "s/\n/,/g" | $SED "s/,$//g" )
    datas=$(cat $tmpcsv.nums | $SED -z "s/\n/,/g" | $SED "s/,$//g")

    cat ${SCRIPT_DIR}/lib/pyplot_pie.py | $SED "s#%%output#${output}#g" | $SED "s#%%labels#${labels}#g" | $SED "s#%%datas#${datas}#g" \
    | $SED "s#%%font_family#$font_family#g" > $pyexe 

  else 
    echo "error: graph type pie can be used only for snapshot"
    exit 1
  fi

  if [ "$title" ];then
    title=$(echo "$title" | $SED "s/{####}/ /g" | $SED "s/{#####}/:/g")
    cat $pyexe | $SED "s/%%title/${title}/g" > $pyexe.title
    pyexe=$pyexe.title
  else
    cat $pyexe | $SED -r "s/(.*)%%title(.*)//g" > $pyexe.title
    pyexe=$pyexe.title
  fi
fi

# gen pygraph
$PYTHON $pyexe 

ls ${pyexe_org}*  >/dev/null 2>&1
if [ $? -eq 0 ];then
  rm ${pyexe_org}* 
fi

ls ${tmpcsv_org}*  >/dev/null 2>&1
if [ $? -eq 0 ];then
  rm ${tmpcsv_org}* 
fi

exit 0
