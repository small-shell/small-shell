#!/bin/bash

# load small-shell conf
. %%www/def/.env

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

  if [[ $param == remote_addr:* ]]; then
    remote_addr=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == user_name:* ]]; then
    user_name=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == user_agent:* ]]; then
    user_agent=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == id:* ]]; then
    id=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [ "$master" ];then
    if [[ $param == redirect* ]];then
      redirect=$(echo "$param" | $AWK -F":" '{print $2}')
    fi
  fi

done

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

# gen databox list for left menu
db_list="$databox $($META get.databox)"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./base?session=$session&pin=$pin&databox=$db&req=import\">$db</option>"\
    >> %%www/tmp/${session}/databox_list
  fi
  ((count +=1 ))
done

# -----------------
# render HTML
# -----------------

if [ ! -d %%www/tmp/${session}/binary_file  ];then

  view="import_form.html.def"
  # overwritten by clustering logic
  if [ "$master" ];then
    if [ "$redirect" = "no" ];then
      view="import_master_failed.html.def"
    fi
  fi

  # render form HTML
  cat %%www/def/${view} | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu" \
  | $SED "/%%common_menu/d"\
  | $SED "s/%%user/${user_name}/g"\
  | $SED "/%%databox_list/r %%www/tmp/${session}/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%databox/${databox}/g"\
  | $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"

else

  # exec import
  ${small_shell_path}/bin/data_import import_file:%%www/tmp/${session}/binary_file/binary.data \
  databox:${databox} session:${session} pin:${pin} remote_addr:${remote_addr} \
  user_agent:${user_agent} > %%www/tmp/${session}/result
  data_import_session=$(cat %%www/tmp/${session}/result | grep Import_session: | $AWK -F "Import_session:" '{print $2}')
  error_check=$(cat %%www/tmp/${session}/result | grep error)

  if [ ! "$error_check" ];then
    echo "<a style=\"cursor: pointer\" onclick=\"window.open('./base?%%params&req=log_viewer&data_import_session=$data_import_session', 'log_viewer', 'width=920,height=280')\">view</a>" >> %%www/tmp/${session}/result
    message="## SUCCESS ##"
  else
    message="please check your import file again"
  fi

  # render HTML
  cat %%www/def/import.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu" \
  | $SED "/%%common_menu/d"\
  | $SED "s/%%user/${user_name}/g"\
  | $SED "/%%databox_list/r %%www/tmp/${session}/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%databox/${databox}/g"\
  | $SED "/%%result/r %%www/tmp/${session}/result" \
  | $SED "s/%%result/${message}/g"\
  | $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"

fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
