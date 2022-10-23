#!/bin/bash

# load small-shell conf
. %%www/descriptor/.small_shell_conf

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

# check posted param

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

if [ ! -d %%www/tmp/$session ];then
  mkdir %%www/tmp/$session
fi

# -----------------
# Exec command
# -----------------

# exec and gen %%result 
sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin databox:$databox \
action:del id:$id  > %%www/tmp/$session/result

# redirect to the table
echo "<meta http-equiv=\"refresh\" content=\"0; url=./shell.app?session=$session&pin=$pin&databox=$databox&req=table\">"

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
