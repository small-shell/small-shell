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

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == data_import_session:* ]]; then
    data_import_session=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ "$id" = "" -a ! "$data_import_session" ];then
  echo "error: please set correct id or session"
  exit 1
fi

if [ ! -d ../tmp/${session}_log ];then
  mkdir ../tmp/${session}_log
fi

# -----------------
# Exec command
# -----------------

if [ ! "$data_import_session" ];then

  # gen %%log contents
  sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin databox:$databox \
  action:get id:$id type:log format:html_tag > ../tmp/${session}_log/log

  # render HTML
  cat ../descriptor/log_viewer.html.def | sed "s/^ *</</g" \
  | sed "/%%log/r ../tmp/${session}_log/log" \
  | sed "s/%%log//g"\
  | sed "s/%%id/$id/g"

else

  # will be changed to meta.sh
  sudo -u small-shell ${small_shell_path}/bin/meta get.progress:$data_import_session > ../tmp/${session}_log/log

  # render HTML
  cat ../descriptor/import_log_viewer.html.def | sed "s/^ *</</g" \
  | sed "s/%%data_import_session/$data_immport_session/g"\
  | sed "/%%log/r ../tmp/${session}_log/log" \
  | sed "s/%%log/-----------------------\n<b>#DATA IMPORT SESSION<\/b>\n------------------------\n/g"

fi

if [ "$session" ];then
  rm -rf ../tmp/${session}_log
fi

exit 0
