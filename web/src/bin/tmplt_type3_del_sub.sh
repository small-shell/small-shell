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
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%parent_app"

# -----------------
# Exec command
# -----------------

# exec and gen %%result 
$DATA_SHELL databox:$databox action:del id:$id > %%www/tmp/$session/result

error_chk=`grep "^error" %%www/tmp/$session/result`

if [ "$error_chk" ];then
  cat %%www/descriptor/%%app_del_err.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/descriptor/common_parts/%%parent_app_common_menu" \
  | $SED "s/%%common_menu//g"\
  | $SED "/%%message/r %%www/tmp/$session/result" \
  | $SED "/%%message/d"\
  | $SED "s/%%session/session=$session\&pin=$pin/g"
else
  # wait index update for other type of server
  if [ ! "$server" = "default" ];then
    numcol=`$META get.header:${databox}{csv} | $SED "s/,/\n/g" | wc -l | tr -d " "`
    buffer=`expr $numcol / 8`
    index_update_time="0.$buffer"
    sleep $index_update_time
  fi

  # redirect to the table
  echo "<meta http-equiv=\"refresh\" content=\"0; url=./%%parent_app?subapp=%%app&session=$session&pin=$pin&req=table\">"
fi


if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
