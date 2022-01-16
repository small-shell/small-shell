#!/bin/bash

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == filter:* ]]; then
    filter=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

if [[ $filter == *{*} ]]; then
  filter_key=`echo $filter | awk -F "{" '{print $1}'`
  filter_word=`echo $filter | awk -F "{" '{print $2}' | sed "s/}//g" | sed "s/%/{%%%%%%%%%%%%%%%%}/g"\
  | sed "s/_/{%%%%%%%}/g" | sed "s/\//{%%%%%}/g"  \
  | sed "s/(/{%%%%%%%%}/g" | sed "s/)/{%%%%%%%%%}/g" | sed "s/\[/{%%%%%%%%%%}/g" | sed "s/\]/{%%%%%%%%%%%}/g" \
  | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" | sed "s/*/{%%%%%%%%%%%%%%%}/g" | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
  | sed "s/,/{%%%%%%}/g"  | sed "s/#/{%%%%%%%%%%%%%}/g" |  sed "s/\&/{%%%%}/g" | sed "s/:/{%%%}/g" | sed "s/　/ /g" | sed "s/ /,/g"\
  | php -r "echo preg_quote(file_get_contents('php://stdin'));"`
  filter_table="$filter_key{$filter_word}"
else
  filter_table=`echo $filter  | sed "s/%/{%%%%%%%%%%%%%%%%}/g" | sed "s/_/{%%%%%%%}/g" | sed "s/\//{%%%%%}/g" | sed "s/,/{%%%%%%}/g" \
  | sed "s/\[/{%%%%%%%%%%}/g" | sed "s/\]/{%%%%%%%%%%%}/g"| sed "s/(/{%%%%%%%%}/g" | sed "s/)/{%%%%%%%%%}/g" | sed "s/|/{%%%%%%%%%%%%}/g" \
  | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" | sed "s/*/{%%%%%%%%%%%%%%%}/g" | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
  | sed "s/#/{%%%%%%%%%%%%%}/g" |  sed "s/\&/{%%%%}/g" | sed "s/:/{%%%}/g" | sed "s/　/ /g" | sed "s/ /,/g" \
  | php -r "echo preg_quote(file_get_contents('php://stdin'));"`
fi

# -----------------
# Exec command
# -----------------

# render csv
if [ ! "$filter" = "%%header" ];then

  if [ "$filter" = "-" ];then
    $DATA_SHELL databox:$databox command:show_all format:csv > ../tmp/$session/csv
  else
    $DATA_SHELL databox:$databox command:show_all[filter=${filter_table}] format:csv > ../tmp/$session/csv
  fi

  cat ../tmp/$session/csv \
  | sed "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | sed "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | sed "s/{%%%%%%%%%%%%%%%}/*/g"\
  | sed "s/{%%%%%%%%%%%%%%}/$/g"\
  | sed "s/{%%%%%%%%%%%%%}/\#/g"\
  | sed "s/{%%%%%%%%%%%%}/|/g"\
  | sed "s/{%%%%%%%%%%%}/\]/g"\
  | sed "s/{%%%%%%%%%%}/\[/g"\
  | sed "s/{%%%%%%%%%}/)/g"\
  | sed "s/{%%%%%%%%}/(/g"\
  | sed "s/{%%%%%%%}/_/g"\
  | sed "s/{%%%%%%}/,/g"\
  | sed "s/{%%%%%}/\//g"\
  | sed "s/{%%%%}/\&/g"\
  | sed "s/{%%%}/:/g"
else
  ${small_shell_path}/bin/meta get.header:$databox{csv}
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
