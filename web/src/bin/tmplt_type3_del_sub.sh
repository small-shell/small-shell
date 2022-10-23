#!/bin/bash

# Target databox and keys
databox=%%databox

# load small-shell conf
. %%www/descriptor/.small_shell_conf


# load query string param
for param in `echo $@`
do

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

# check posted param

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

if [ ! -d %%www/tmp/$session ];then
  mkdir %%www/tmp/$session
fi

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%parent_app"

# -----------------
# Exec command
# -----------------

# exec and gen %%result 
$DATA_SHELL databox:$databox action:del id:$id > %%www/tmp/$session/result

# redirect to the table
echo "<meta http-equiv=\"refresh\" content=\"0; url=./%%parent_app?subapp=%%app&session=$session&pin=$pin&req=table\">"

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
