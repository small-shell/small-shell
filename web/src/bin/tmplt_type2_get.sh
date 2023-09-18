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

  if [[ $param == id:* ]]; then
    id=`echo $param | $AWK -F":" '{print $2}'`
  fi

done

if [ ! "$id"  ];then
  id="new"
fi

if [ ! -d %%www/tmp/$session ];then
  mkdir %%www/tmp/$session
fi

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

if [ $id = "new" ];then

  # gen reqd/write form #new
  $DATA_SHELL databox:%%databox action:get id:$id keys:%%keys format:html_tag > %%www/tmp/$session/dataset

else

  # gen read only contents
  $DATA_SHELL databox:%%databox action:get id:$id keys:%%keys format:none > %%www/tmp/$session/dataset.0.1
  cat %%www/tmp/$session/dataset.0.1 | $SED "s/^/<li><label>/g" | $SED "s/:/<\/label><pre>/1" | $SED "s/$/<\/pre><\/li>/g" \
  | $SED "s/<pre><\/pre>/<pre>-<\/pre>/g" | $SED "s/_%%enter_/\n/g" > %%www/tmp/$session/dataset

  # history #default is head -1
  $DATA_SHELL databox:%%databox action:get type:log id:$id format:none | head -1 > %%www/tmp/$session/history

  # error check
  error_chk=`cat %%www/tmp/$session/dataset.0.1 | grep "^error:"`
fi


# form type check
form_chk=`$META chk.form:%%databox`

# set view
if [ "$error_chk" ];then
  view="%%app_get_err.html.def"

elif [ "$form_chk" = "urlenc" ];then
  if [ "$id" = "new" ];then
    view="%%app_get_new.html.def"
  else
    view="%%app_get.html.def"
  fi
elif [ "$form_chk" = "multipart" ];then
  if [ "$id" = "new" ];then
    view="%%app_get_new_incf.html.def"
  else
    view="%%app_get.html.def"
  fi
fi

# render HTML
cat %%www/descriptor/${view} | $SED -r "s/^( *)</</1" \
| $SED "/%%dataset/r %%www/tmp/$session/dataset" \
| $SED "s/%%dataset//g"\
| $SED "/%%history/r %%www/tmp/$session/history" \
| $SED "s/%%history//g"\
| $SED "s/%%id/$id/g" \
| $SED "s/%%pdls/session=$session\&pin=$pin\&req=get/g" \
| $SED "s/%%session/session=$session\&pin=$pin/g" \
| $SED "s/%%params/session=$session\&pin=$pin/g"

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
