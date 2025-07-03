#!/bin/bash
app=%%app

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
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:$app"

# -----------------
# Handle markdown
# -----------------
num_of_md_def=`$META get.num:${app}.UI.md.def`
if [ $num_of_md_def -ge 1 ];then
  if [ -f %%www/descriptor/.${app}.UI.md.def.hash ];then
    hash=`$META get.chain:${app}.UI.md.def | tail -1 | $AWK -F ":" '{print $4}'`
    org_hash="`cat %%www/descriptor/.${app}.UI.md.def.hash`"
    if [ ! "$hash" = "$org_hash" ];then
      echo "$hash" > %%www/descriptor/.${app}.UI.md.def.hash
      %%www/bin/md_parse.sh $app $session $pin
    fi
  else
    hash=`$META get.chain:${app}.UI.md.def | tail -1 | $AWK -F ":" '{print $4}'`
    echo "$hash" > %%www/descriptor/.${app}.UI.md.def.hash
    %%www/bin/md_parse.sh $app $session $pin
  fi
fi

# ----------------
# Handle calendar
# ----------------

chk_calendar=`grep "<div id=\"my-calendar\">"  %%www/descriptor/%%app_main.html.def`

if [ "$chk_calendar" ];then
  $DATA_SHELL databox:%%app.events command:show_all format:json \
  | $SED "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | $SED "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | $SED "s/{%%%%%%%%%%%%%%%}/*/g"\
  | $SED "s/{%%%%%%%%%%%%%%}/$/g"\
  | $SED "s/{%%%%%%%%%%%%%}/\#/g"\
  | $SED "s/{%%%%%%%%%%%%}/|/g"\
  | $SED "s/{%%%%%%%%%%%}/\]/g"\
  | $SED "s/{%%%%%%%%%%}/\[/g"\
  | $SED "s/{%%%%%%%%%}/)/g"\
  | $SED "s/{%%%%%%%%}/(/g"\
  | $SED "s/{%%%%%%%}/_/g"\
  | $SED "s/{%%%%%%}/,/g"\
  | $SED "s/{%%%%%}/\//g"\
  | $SED "s/{%%%%}/\&/g"\
  | $SED "s/{%%%}/:/g" > /var/www/tmp/$session/events
fi


# -----------------
# render HTML
# -----------------

cat %%www/descriptor/%%app_main.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%common_menu/r %%www/descriptor/common_parts/%%app_common_menu" \
| $SED "s/%%common_menu//g"\
| $SED "/%%events/r /var/www/tmp/$session/events" \
| $SED "s/%%user/$user_name/g" \
| $SED "s/%%session/session=$session\&pin=$pin/g" \
| $SED "s/%%params/session=$session\&pin=$pin/g"

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
