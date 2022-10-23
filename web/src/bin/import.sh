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

  if [[ $param == remote_addr:* ]]; then
    remote_addr=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ ! -d %%www/tmp/$session ];then
  mkdir %%www/tmp/$session
fi

# gen databox list for left menu
db_list="$databox `$META get.databox`"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./shell.app?session=$session&pin=$pin&databox=$db&req=import\">DataBox:$db</option>"\
    >> %%www/tmp/$session/databox_list
  fi
  ((count +=1 ))
done

# -----------------
# render HTML
# -----------------

if [ ! -d %%www/tmp/$session/binary_file  ];then

  # render form HTML
  cat %%www/descriptor/import_form.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/descriptor/common_parts/common_menu" \
  | $SED "/%%common_menu/d"\
  | $SED "/%%footer/r %%www/descriptor/common_parts/footer" \
  | $SED "/%%footer/d"\
  | $SED "/%%databox_list/r %%www/tmp/$session/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%databox/$databox/g"\
  | $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"

else

  # gen %%result contents
  sudo -u small-shell ${small_shell_path}/bin/data_import %%www/tmp/$session/binary_file/binary.data \
  $databox $session $pin $remote_addr > %%www/tmp/$session/result
  data_import_session=`cat %%www/tmp/$session/result | grep Import_session: | $AWK -F "Import_session:" '{print $2}'`

  error_check=`cat %%www/tmp/$session/result | grep error`
  if [ ! "$error_check" ];then
    echo "<a style=\"cursor: pointer\" onclick=\"window.open('./shell.app?%%params&req=log_viewer&data_import_session=$data_import_session', 'log_viewer', 'width=920,height=280')\">view</a>" >> %%www/tmp/$session/result
    message="## STARTED ##"
  else
    message="please check your import file again"
  fi

  # render HTML
  cat %%www/descriptor/import.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%common_menu/r %%www/descriptor/common_parts/common_menu" \
  | $SED "/%%common_menu/d"\
  | $SED "/%%footer/r %%www/descriptor/common_parts/footer" \
  | $SED "/%%footer/d"\
  | $SED "/%%databox_list/r %%www/tmp/$session/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%databox/$databox/g"\
  | $SED "/%%result/r %%www/tmp/$session/result" \
  | $SED "s/%%result/$message/g"\
  | $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"

fi

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
