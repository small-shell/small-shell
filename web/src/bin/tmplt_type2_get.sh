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

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ ! "$id"  ];then
  id="new"
fi

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

if [ $id = "new" ];then

  # gen reqd/write form #new
  $DATA_SHELL databox:%%databox action:get id:$id keys:%%keys format:html_tag > ../tmp/$session/dataset

else

  # gen read only contents
  $DATA_SHELL databox:%%databox action:get id:$id keys:%%keys format:none > ../tmp/$session/dataset.0.1
  cat ../tmp/$session/dataset.0.1 | sed "s/^/<li><label>/g" | sed "s/:/<\/label><pre>/1" | sed "s/$/<\/pre><\/li>/g" \
  | sed "s/<pre><\/pre>/<pre>-<\/pre>/g" | sed "s/_%%enter_/\n/g" > ../tmp/$session/dataset

  # history #default is head -1
  $DATA_SHELL databox:%%databox action:get type:log id:$id format:none | head -1 > ../tmp/$session/history

fi

# render HTML
if [ "$id" = "new" ];then
  cat ../descriptor/%%app_get_new.html.def | sed -r "s/^( *)</</1" \
  | sed "/%%dataset/r ../tmp/$session/dataset" \
  | sed "s/%%dataset//g"\
  | sed "s/%%id/$id/g" \
  | sed "s/%%params/session=$session\&pin=$pin/g"
else
  cat ../descriptor/%%app_get.html.def | sed -r "s/^( *)</</1" \
  | sed "/%%dataset/r ../tmp/$session/dataset" \
  | sed "s/%%dataset//g"\
  | sed "/%%history/r ../tmp/$session/history" \
  | sed "s/%%history//g"\
  | sed "s/%%id/$id/g" \
  | sed "s/%%params/session=$session\&pin=$pin/g"
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
