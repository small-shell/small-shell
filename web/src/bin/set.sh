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

# form type check
form_chk=$(${small_shell_path}/bin/meta chk.form:$databox)

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
# Exec 
# -----------------

# set and get %%result contents
${small_shell_path}/bin/DATA_shell session:$session pin:$pin databox:$databox \
action:set id:$id keys:$keys input_dir:%%www/tmp/${session} > %%www/tmp/${session}/result

error_chk=$(grep "^error" %%www/tmp/${session}/result)

if [ "$error_chk" ];then
  cat %%www/def/set_err.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu" \
  | $SED "s/%%common_menu//g"\
  | $SED "s/%%user/${user_name}/g"\
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

  # redirect to the table if it's not md.def
  if [[ $databox == *.md.def ]];then
    echo "<meta http-equiv=\"refresh\" content=\"0; url=./base?session=$session&pin=$pin&databox=$databox&req=get&id=${id}\">"
  else
    echo "<meta http-equiv=\"refresh\" content=\"0; url=./base?session=$session&pin=$pin&databox=$databox&req=table\">"
  fi

fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
