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

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

# load env
. ${SCRIPT_DIR}/env

if [  ! -x $PYTHON ];then
  echo "please define executable path of python on ${SCRIPT_DIR}/env if you want to gen graph"
  exit 0
fi

# load param
for param in `echo $@`
do
  if [[ $param == type:* ]]; then
    type=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == *:*} ]]; then
    min=$param
    type="$type $min"
  fi

  if [[ $param == input:* ]]; then
    input=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == output:* ]]; then
    output=`echo $param | awk -F":" '{print $2}'`
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
done

if [ ! "$type" ];then
  echo "error: please input graph type"
  exit 1
fi

if [ ! "$input" ];then
  echo "error: please define input csv file"
  exit 1
fi

if [ ! "$output" ];then
  output=${ROOT}/util/statistics/graph/`date +%Y%m%d`.png
fi

if [[ ! $output == *.png ]]; then
  echo "output file must be \$PATH/\$name.png"
  exit 1
fi

function time_fmt_chk(){
  fmt_chk=`cat $input | head -1 | awk -F "," '{print $1}'` 
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

pyexe=${SCRIPT_DIR}/pyexe/exec.`date +%s`.$RANDOM
pyexe_org=$pyexe

tmpcsv=${SCRIPT_DIR}/pyexe/csv.`date +%s`.$RANDOM
tmpcsv_org=$tmpcsv


if [[ $type == line* ]]; then
 
  timeline=`echo $type | awk -F "," '{print $2}'`

  case "$timeline" in 

  "hourly" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat ${SCRIPT_DIR}/lib/pandas_line_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%axasis#ax.xaxis.set_major_formatter(mdates.DateFormatter(\"%H:%M:%S\"))#g" > $pyexe ;;

  "daily" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat ${SCRIPT_DIR}/lib/pandas_line_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%axasis#ax.xaxis.set_major_formatter(mdates.DateFormatter(\"%Y-%m-%d %H:%M\"))#g" > $pyexe ;;

  "monthly" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat ${SCRIPT_DIR}/lib/pandas_line_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%axasis#ax.xaxis.set_major_formatter(mdates.DateFormatter(\"%Y-%m-%d\"))#g" > $pyexe ;;

  esac
    
  if [ "$title" ];then
    title=`echo $title | sed "s/{####}/ /g"`
    cat $pyexe | sed "s/%%title/$title/g" > $pyexe.title
    pyexe=$pyexe.title
  else
    cat $pyexe | sed -r "s/(.*)%%title(.*)//g" > $pyexe.title
    pyexe=$pyexe.title
  fi

  if [ "$X_label" ];then
    cat $pyexe | sed "s/%%X_label/$X_label/g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  else
    cat $pyexe | sed -r "s/(.*)%%X_label(.*)//g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  fi

  if [ "$Y_label" ];then
    cat $pyexe | sed "s/%%Y_label/$Y_label/g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  else
    cat $pyexe | sed -r "s/(.*)%%Y_label(.*)//g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  fi

fi

if [[ $type == bar* ]]; then                                                                                                                                
  timeline=`echo $type | awk -F "," '{print $2}'`
                                                                                                                                                               case "$timeline" in

  "hourly" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat $input | sed -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" | sed -r "s/:([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_bar_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%index#Time#g" | sed "s#%%legend#True#g" > $pyexe ;;

  "daily" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat $input | sed -r "s/ ([0-9]*):([0-9]*):([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_bar_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%index#Time#g" | sed "s#%%legend#True#g"  > $pyexe ;;

  "monthly" )
    time_fmt_chk

    # gen pyexe with changing time format
    cat $input | sed -r "s/ ([0-9]*):([0-9]*):([0-9]*),/,/g"  > $tmpcsv
    input=$tmpcsv
    cat ${SCRIPT_DIR}/lib/pandas_bar_plot.py | sed "s#%%output#$output#g" | sed "s#%%csv#$input#g" | sed "s#%%font_family#$font_family#g" \
    | sed "s#%%index#Time#g" | sed "s#%%legend#True#g"  > $pyexe ;;

  snapshot* )
    cat $input | head -1 | sed "s/Time,//g" | sed "s/,/\n/g" > $tmpcsv.items
    time=`echo $timeline | awk -F "{" '{print $2}' | sed "s/}//g"`
    grep "$time" $input | sed -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" \
    | sed -r "s/([0-9]*):([0-9]*):([0-9]*),//g" | sed "s/,/\n/g" > $tmpcsv.nums

    # gen python list
    labels=`cat $tmpcsv.items | sed "s/^/\'/g" | sed "s/$/\'/g" | sed -z "s/\n/,/g" | sed "s/,$//g" `
    datas=`cat $tmpcsv.nums | sed -z "s/\n/,/g" | sed "s/,$//g" `

    cat ${SCRIPT_DIR}/lib/pyplot_bar_snap.py | sed "s#%%output#$output#g" | sed "s#%%labels#$labels#g" | sed "s#%%datas#$datas#g" \
    | sed "s#%%font_family#$font_family#g" > $pyexe ;;
    
  esac

  if [ "$title" ];then
    title=`echo $title | sed "s/{####}/ /g" | sed "s/{#####}/:/g"`
    cat $pyexe | sed "s/%%title/$title/g" > $pyexe.title
    pyexe=$pyexe.title
  else
    cat $pyexe | sed -r "s/(.*)%%title(.*)//g" > $pyexe.title
    pyexe=$pyexe.title
  fi

  if [ "$X_label" ];then
    X_label=`echo $X_label | sed "s/{####}/ /g" | sed "s/{#####}/:/g"`
    cat $pyexe | sed "s/%%X_label/$X_label/g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  else
    cat $pyexe | sed -r "s/(.*)%%X_label(.*)//g" > $pyexe.X_label
    pyexe=$pyexe.X_label
  fi

  if [ "$Y_label" ];then
    Y_label=`echo $Y_label | sed "s/{####}/ /g" | sed "s/{#####}/:/g"`
    cat $pyexe | sed "s/%%Y_label/$Y_label/g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  else
    cat $pyexe | sed -r "s/(.*)%%Y_label(.*)//g" > $pyexe.Y_label
    pyexe=$pyexe.Y_label
  fi

fi

if [[ $type == pie* ]]; then
  timeline=`echo $type | awk -F "," '{print $2}'`
                                                                                                                                                               case "$timeline" in
  snapshot* )

    cat $input | head -1 | sed "s/Time,//g" | sed "s/,/\n/g" > $tmpcsv.items
    time=`echo $timeline | awk -F "{" '{print $2}' | sed "s/}//g"`
    grep "$time" $input | sed -r "s/^([0-9]*)-([0-9]*)-([0-9]*) //g" \
    | sed -r "s/([0-9]*):([0-9]*):([0-9]*),//g" | sed "s/,/\n/g" > $tmpcsv.nums

    # gen python list
    labels=`cat $tmpcsv.items | sed "s/^/\'/g" | sed "s/$/\'/g" | sed -z "s/\n/,/g" | sed "s/,$//g" `
    datas=`cat $tmpcsv.nums | sed -z "s/\n/,/g" | sed "s/,$//g" `

    cat ${SCRIPT_DIR}/lib/pyplot_pie.py | sed "s#%%output#$output#g" | sed "s#%%labels#$labels#g" | sed "s#%%datas#$datas#g" \
    | sed "s#%%font_family#$font_family#g" > $pyexe ;;

  esac

  if [ "$title" ];then
    title=`echo $title | sed "s/{####}/ /g" | sed "s/{#####}/:/g"`
    cat $pyexe | sed "s/%%title/$title/g" > $pyexe.title
    pyexe=$pyexe.title
  else
    cat $pyexe | sed -r "s/(.*)%%title(.*)//g" > $pyexe.title
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
