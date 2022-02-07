#!/bin/bash

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

  if [[ $param == remote_addr:* ]]; then
    remote_addr=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# gen databox list for left menu
db_list="$databox `$META get.databox`"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./shell.app?session=$session&pin=$pin&databox=$db&req=import\">DataBox:$db</option>"\
    >> ../tmp/$session/databox_list
  fi
  ((count +=1 ))
done

# -----------------
# render HTML
# -----------------

if [ ! -d ../tmp/$session/binary_file  ];then

  # render form HTML
  cat ../descriptor/import_form.html.def | sed "s/^ *</</g" \
  | sed "/%%common_menu/r ../descriptor/common_parts/common_menu" \
  | sed "/%%common_menu/d"\
  | sed "/%%footer/r ../descriptor/common_parts/footer" \
  | sed "/%%footer/d"\
  | sed "/%%databox_list/r ../tmp/$session/databox_list" \
  | sed "s/%%databox_list//g"\
  | sed "s/%%databox/$databox/g"\
  | sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"

else

  # gen %%result contents
  sudo -u small-shell ${small_shell_path}/bin/data_import ../tmp/$session/binary_file/binary.data \
  $databox $session $pin $remote_addr > ../tmp/$session/result
  data_import_session=`cat ../tmp/$session/result | grep Import_session: | awk -F "Import_session:" '{print $2}'`

  error_check=`cat ../tmp/$session/result | grep error`
  if [ ! "$error_check" ];then
    echo "<a style=\"cursor: pointer\" onclick=\"window.open('./shell.app?%%params&req=log_viewer&data_import_session=$data_import_session', 'log_viewer', 'width=920,height=280')\">view</a>" >> ../tmp/$session/result
    message="## STARTED ##"
  else
    message="please check your import file again"
  fi

  # render HTML
  cat ../descriptor/import.html.def | sed "s/^ *</</g" \
  | sed "/%%common_menu/r ../descriptor/common_parts/common_menu" \
  | sed "/%%common_menu/d"\
  | sed "/%%footer/r ../descriptor/common_parts/footer" \
  | sed "/%%footer/d"\
  | sed "/%%databox_list/r ../tmp/$session/databox_list" \
  | sed "s/%%databox_list//g"\
  | sed "s/%%databox/$databox/g"\
  | sed "/%%result/r ../tmp/$session/result" \
  | sed "s/%%result/$message/g"\
  | sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"

fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
