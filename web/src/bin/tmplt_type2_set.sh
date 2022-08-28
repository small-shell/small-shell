#!/bin/bash

# load small-shell conf
. ../descriptor/.small_shell_conf

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


# -----------------
# Exec command
# -----------------

# BASE COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# form type check
form_chk=`$META chk.form:%%databox`
if [ "$form_chk" = "multipart" ];then
  file_key=`cat ../tmp/$session/binary_file/input_name`
  cat ../tmp/$session/binary_file/file_name > ../tmp/$session/$file_key 2>/dev/null
fi

# check posted param
if [ -d ../tmp/$session ];then
  keys=`ls ../tmp/$session | grep -v binary_file | $SED -z "s/\n/,/g" | $SED "s/,$//g"`
else
  echo "error: No param posted"
  exit 1
fi

if [ "$id" = "" ];then
  echo "error: please set correct id"
  exit 1
fi

# push datas to databox
$DATA_SHELL databox:%%databox action:set id:$id keys:$keys input_dir:../tmp/$session  > ../tmp/$session/result

# result check
updated_id=`cat ../tmp/$session/result | grep "^successfully set" | $AWK -F "id:" '{print $2}' | $SED '/^$/d' | sort | uniq`

# set message
if [ "$updated_id" ];then
  echo "<h2>SUCCESSFULLY SUBMITTED</h2>" > ../tmp/$session/message
  echo "<a href=\"./%%app?req=get&id=$updated_id\"><p><b>YOUR LINK</b></p></a>" >> ../tmp/$session/message
else
  echo "<h2>Failed, something is wrong. please contact to your web admin</h2>" > ../tmp/$session/message
fi

# -----------------
# render HTML
# -----------------
cat ../descriptor/%%app_set.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%message/r ../tmp/$session/message" \
| $SED "s/%%message/$message/g"\
| $SED "s/%%id/$id/g"

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
