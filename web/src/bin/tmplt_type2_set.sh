#!/bin/bash

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

  if [[ $param == id:* ]]; then
    id=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done


# -----------------
# Exec command
# -----------------

# BASE COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# form type check
form_chk=$($META chk.form:%%databox)
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

# push datas to databox
$DATA_SHELL databox:%%databox action:set id:$id keys:$keys input_dir:%%www/tmp/${session}  > %%www/tmp/${session}/result

# result check
updated_id=$(cat %%www/tmp/${session}/result | grep "^successfully set" | $AWK -F "id:" '{print $2}' | $SED '/^$/d' | sort | uniq)

# set message
if [ "$updated_id" ];then
  echo "<h2>SUCCESSFULLY SUBMITTED</h2>" > %%www/tmp/${session}/message
  echo "<a href=\"./%%app?req=get&id=${updated_id}\"><p><b>YOUR LINK</b></p></a>" >> %%www/tmp/${session}/message
else
  echo "<h2>Failed, something is wrong. please contact to your web admin.</h2>" > %%www/tmp/${session}/message
fi

# -----------------
# render HTML
# -----------------
cat %%www/def/%%app_set.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%message/r %%www/tmp/${session}/message" \
| $SED "s/%%message/${message}/g" \
| $SED "s/%%id/${updated_id}/g"

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
