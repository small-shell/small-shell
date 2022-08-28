#!/bin/bash

# load small-shell conf
. ../descriptor/.small_shell_conf

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

# form type check
form_chk=`${small_shell_path}/bin/meta chk.form:$databox`

if [ "$form_chk" = "multipart" ];then
   file_key=`cat ../tmp/$session/binary_file/input_name`
   cat ../tmp/$session/binary_file/file_name > ../tmp/$session/$file_key 2>/dev/null
fi

# check posted param
if [ -d ../tmp/$session ];then
  keys=`ls ../tmp/$session | grep -v binary_file | $SED -z "s/\n/,/g" | $SED "s/,$//g"`
else
  echo "error: No param posted"
  exit 1
fi

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

# -----------------
# Exec 
# -----------------

# set and get %%result contents
sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin databox:$databox \
action:set id:$id keys:$keys input_dir:../tmp/$session > ../tmp/$session/result

error_chk=`grep "^error" ../tmp/$session/result`

if [ "$error_chk" ];then
  cat ../descriptor/set_err.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r ../descriptor/common_parts/common_menu" \
  | $SED "s/%%common_menu//g"\
  | $SED "/%%message/r ../tmp/$session/result" \
  | $SED "/%%message/d"\
  | $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"
else

  # wait index update
  numcol=`${small_shell_path}/bin/meta get.header:${databox}{csv} | $SED "s/,/\n/g" | wc -l | tr -d " "`
  buffer=`expr $numcol / 8`
  index_update_time="0.$buffer"
  sleep $index_update_time

  # redirect to the table
  echo "<meta http-equiv=\"refresh\" content=\"0; url=./shell.app?session=$session&pin=$pin&databox=$databox&req=table\">"
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
