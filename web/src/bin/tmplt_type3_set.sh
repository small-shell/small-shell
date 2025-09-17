#!/bin/bash

# Target databox and keys
databox=%%databox

# load small-shell conf
. %%www/def/.small_shell_conf

# load query string param
for param in $(echo $@)
do

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

  # handle calendar events
  if [[ $param == *.events ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
    databox=$databox
  fi

done

# BASE COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# form type check
form_chk=$($META chk.form:$databox)
if [ "$form_chk" = "multipart" ];then
  file_key=$(cat %%www/tmp/${session}/binary_file/input_name)
  cat %%www/tmp/${session}/binary_file/file_name > %%www/tmp/${session}/${file_key} 2>/dev/null
fi

# check posted param
if [ -d %%www/tmp/${session} ];then
  keys=$(ls %%www/tmp/${session} | grep -v binary_file | $SED -z "s/\n/,/g" | $SED "s/,$//g")
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
$DATA_SHELL databox:$databox action:set id:$id keys:$keys input_dir:%%www/tmp/${session}  > %%www/tmp/${session}/result

error_chk=$(grep "^error" %%www/tmp/${session}/result)

if [ "$error_chk" ];then
  cat %%www/def/%%app_set_err.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/def/common_parts/%%app_common_menu" \
  | $SED "s/%%common_menu//g"\
  | $SED "s/%%user/${user_name}/g"\
  | $SED "/%%message/r %%www/tmp/${session}/result" \
  | $SED "/%%message/d"\
  | $SED "s/%%session/session=${session}\&pin=${pin}/g"
else
  # wait index update for other type of server
  if [ ! "$server" = "default" ];then
    numcol=$($META get.header:${databox}{csv} | $SED "s/,/\n/g" | wc -l | tr -d " ")
    buffer=$(expr $numcol / 8)
    index_update_time="0.$buffer"
    sleep $index_update_time
  fi

  # redirect to the table
  echo "<meta http-equiv=\"refresh\" content=\"0; url=./%%app?session=$session&pin=$pin&req=table\">"

fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
