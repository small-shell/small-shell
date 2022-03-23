#!/bin/bash

# load query string param
for param in `echo $@`
do

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# -----------------
# Exec command
# -----------------

# SET BASE_COMMAND
#META="sudo -u small-shell ${small_shell_path}/bin/meta"
#DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# -----------------
# render HTML
# -----------------

cat ../descriptor/%%app_main.html.def | sed "s/^ *</</g" \
| sed "/%%common_menu/r ../descriptor/common_parts/%%app_common_menu" \
| sed "s/%%common_menu//g"\
| sed "s/%%user_name/$user_name/g" \
| sed "s/%%session/session=$session\&pin=$pin/g" \
| sed "s/%%params/session=$session\&pin=$pin/g"

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
