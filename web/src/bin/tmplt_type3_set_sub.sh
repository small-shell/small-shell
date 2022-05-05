#!/bin/bash

# Target databox and keys
databox=%%databox

# load query string param
for param in `echo $@`
do

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# BASE COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%parent_app"

# form type check
form_chk=`$META chk.form:$databox`
if [ "$form_chk" = "multipart" ];then
  file_key=`cat ../tmp/$session/binary_file/input_name`
  cat ../tmp/$session/binary_file/file_name > ../tmp/$session/$file_key 2>/dev/null
fi


# check posted param
if [ -d ../tmp/$session ];then
  keys=`ls ../tmp/$session | sed -z "s/\n/,/g" | sed "s/,$//g" | sed "s/binary_file//g"`
else
  echo "error: No param posted"
  exit 1
fi

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

# -----------------
# Exec command
# -----------------

# push datas to databox
$DATA_SHELL databox:$databox action:set id:$id keys:$keys input_dir:../tmp/$session  > ../tmp/$session/result

error_chk=`grep "^error" ../tmp/$session/result`

if [ "$error_chk" ];then
  cat ../descriptor/%%app_set.html.def | sed -r "s/^( *)</</1" \
  | sed "/%%common_menu/r ../descriptor/common_parts/%%parent_app_common_menu" \
  | sed "s/%%common_menu//g"\
  | sed "/%%message/r ../tmp/$session/result" \
  | sed "/%%message/d"\
  | sed "s/%%session/session=$session\&pin=$pin/g"
else
  # wait index update
  numcol=`$META get.header:${databox}{csv} | sed "s/,/\n/g" | wc -l`
  buffer=`expr $numcol / 8`
  index_update_time="0.$buffer"
  sleep $index_update_time

  # redirect to the table
  echo "<meta http-equiv=\"refresh\" content=\"0; url=./%%parent_app?subapp=%%app&session=$session&pin=$pin&req=table\">"
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
