#!/bin/bash

# Target databox and keys
databox=%%databox
key=all

# load query string param
for param in `echo $@`
do

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ ! -d ../tmp/${session}_log ];then
  mkdir ../tmp/${session}_log
fi

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%parent_app"

# -----------------
# Exec command
# -----------------

# gen %%log contents
if [ "$keys" = "all" ];then
  $DATA_SHELL databox:$databox \
  action:get id:$id type:log format:html_tag > ../tmp/${session}_log/log
else
  GREP=`echo $keys | sed "s/^/grep -e \"<pre>\" -e \"<\/pre>\" -e key:/g" | sed "s/,/ -e key:/g"`
  LOG_GREP="$DATA_SHELL databox:$databox action:get id:$id type:log | $GREP"
  eval $LOG_GREP > ../tmp/${session}_log/log
fi

# render HTML
cat ../descriptor/%%app_log_viewer.html.def | sed -r "s/^( *)</</1" \
| sed "/%%log/r ../tmp/${session}_log/log" \
| sed "s/%%log//g"\
| sed "s/%%id/$id/g"

if [ "$session" ];then
  rm -rf ../tmp/${session}_log
fi

exit 0
