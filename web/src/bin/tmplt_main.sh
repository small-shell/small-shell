#!/bin/bash

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

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

if [ ! -d %%www/tmp/$session ];then
  mkdir %%www/tmp/$session
fi

# -----------------
# Exec command
# -----------------

# SET BASE_COMMAND
#META="${small_shell_path}/bin/meta"
#DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# -----------------
# render HTML
# -----------------

cat %%www/descriptor/%%app_main.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%common_menu/r %%www/descriptor/common_parts/%%app_common_menu" \
| $SED "s/%%common_menu//g"\
| $SED "s/%%user_name/$user_name/g" \
| $SED "s/%%session/session=$session\&pin=$pin/g" \
| $SED "s/%%params/session=$session\&pin=$pin/g"

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
