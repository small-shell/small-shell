#!/bin/bash

# load small-shell conf
. %%www/def/.small_shell_conf

# load query string param
for param in $(echo $@)
do

  if [[ $param == databox:* ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == session:* ]]; then
    session=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == pin:* ]]; then
    pin=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == user_name:* ]]; then
    user_name=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == id:* ]]; then
    id=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done

# check posted param

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

# -----------------
# Exec command
# -----------------

# exec and gen %%result 
${small_shell_path}/bin/DATA_shell session:$session pin:$pin databox:$databox \
action:del id:$id  > %%www/tmp/${session}/result
error_chk=$(grep "^error" %%www/tmp/${session}/result)
  
if [ "$error_chk" ];then
  cat %%www/def/del_err.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu" \
  | $SED "s/%%common_menu//g"\
  | $SED "/%%message/r %%www/tmp/${session}/result" \
  | $SED "/%%message/d"\
  | $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"
else
    
  # wait index update for other type of server
  if [ ! "$server" = "default" ];then
    numcol=$(${small_shell_path}/bin/meta get.header:${databox}{csv} | $SED "s/,/\n/g" | wc -l | tr -d " ")
    buffer=$(expr $numcol / 8)
    index_update_time="0.$buffer"
    sleep $index_update_time
  fi

  # redirect to the table
  echo "<meta http-equiv=\"refresh\" content=\"0; url=./base?session=$session&pin=$pin&databox=$databox&req=table\">"
fi 

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
