#!/bin/bash

# Target databox and keys
databox=%%databox
keys=all

# load small-shell conf
. %%www/descriptor/.small_shell_conf

# load query string param
for param in `echo $@`
do

  if [[ $param == session:* ]]; then
    session=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

if [ ! -d %%www/tmp/${session}_log ];then
  mkdir %%www/tmp/${session}_log
fi

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# -----------------
# Exec command
# -----------------

# gen %%log contents

if [ "$keys" = "all" ];then
  $DATA_SHELL databox:$databox \
  action:get id:$id type:log format:html_tag > %%www/tmp/${session}_log/log
else
  GREP=`echo $keys | $SED "s/^/grep -e \"<pre>\" -e \"<\/pre>\" -e key:/g" | $SED "s/,/ -e key:/g"`
  LOG_GREP="$DATA_SHELL databox:$databox action:get id:$id type:log | $GREP"
  eval $LOG_GREP > %%www/tmp/${session}_log/log
fi

# render HTML
cat %%www/descriptor/%%app_log_viewer.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%log/r %%www/tmp/${session}_log/log" \
| $SED "s/%%log//g"\
| $SED "s/%%id/$id/g"

if [ "$session" ];then
  rm -rf %%www/tmp/${session}_log
fi

exit 0
