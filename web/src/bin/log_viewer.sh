#!/bin/bash

# load small-shell conf
. ../descriptor/.small_shell_conf

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

  if [[ $param == id:* ]]; then
    id=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == data_import_session:* ]]; then
    data_import_session=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

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
  cat ../descriptor/log_viewer.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%log/r ../tmp/${session}_log/log" \
  | $SED "s/%%log//g"\
  | $SED "s/%%id/$id/g"

else

  # will be changed to meta.sh
  sudo -u small-shell ${small_shell_path}/bin/meta get.progress:$data_import_session > ../tmp/${session}_log/log

  # render HTML
  cat ../descriptor/import_log_viewer.html.def | $SED -r "s/^( *)</</1" \
  | $SED "s/%%data_import_session/$data_immport_session/g"\
  | $SED "/%%log/r ../tmp/${session}_log/log" \
  | $SED "s/%%log/-----------------------\n<b>#DATA IMPORT SESSION<\/b>\n------------------------\n/g"

fi

if [ "$session" ];then
  rm -rf ../tmp/${session}_log
fi

exit 0
