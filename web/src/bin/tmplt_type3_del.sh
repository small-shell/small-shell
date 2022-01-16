#!/bin/bash

# Target databox and keys
databox=%%databox

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

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# check posted param

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# -----------------
# Exec command
# -----------------

# exec and gen %%result 
$DATA_SHELL databox:$databox action:del id:$id > ../tmp/$session/result

# redirect to the table
echo "<meta http-equiv=\"refresh\" content=\"0; url=./%%app?session=$session&pin=$pin&req=table\">"

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
