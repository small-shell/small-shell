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

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == duplicate:* ]]; then
    duplicate=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ "$id" = "" ];then
  echo "error: please set correct id"
fi

if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# gen databox list for left menu
db_list="$databox `$META get.databox`"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./shell.app?session=$session&pin=$pin&databox=$db&req=get&id=new\">DataBox:$db</option>"\
    >> ../tmp/$session/databox_list
  fi
  ((count +=1 ))
done

# -----------------
# Exec  command
# -----------------

# load permission
permission=`$META get.attr:$user_name{permission}`

if [ ! "$duplicate" = "yes" ];then

  # gen %%data contents
  $DATA_SHELL databox:$databox \
  action:get id:$id keys:all format:html_tag > ../tmp/$session/dataset

else

  # else means copying data
  keys=`$META get.key:$databox{all}`
  count=1
  for key in $keys
  do
     # gen %%data by conpying
    if [ "$count" = 1 ];then
      $DATA_SHELL databox:$databox \
      action:get id:new key:$key format:html_tag > ../tmp/$session/dataset
    else
      data=`$DATA_SHELL databox:$databox \
      action:get id:$id key:$key format:html_tag ` \
      file_chk=`echo $data | grep "<div class=\"file_form\">" `

      if [ ! "$file_chk" ];then
        echo $data >> ../tmp/$session/dataset
      else
        $DATA_SHELL databox:$databox \
        action:get id:new key:$key format:html_tag  >> ../tmp/$session/dataset
      fi

    fi
    (( count += 1 ))
  done
  id=new

fi

# error check
error_chk=`cat ../tmp/$session/dataset | grep "^error: there is no primary_key:"`

# form type check
form_chk=`$META chk.form:$databox`


# -----------------
# render HTML
# -----------------

# set view
if [ "$error_chk" ];then
  view="get_err.html.def"

elif [ "$permission"  = "ro" ];then
  view="get_ro.html.def"

elif [ "$form_chk" = "urlenc" ];then
  if [ "$id" = "new" ];then
    view="get_new.html.def"
  else
    view="get_rw.html.def"
  fi
elif [ "$form_chk" = "multipart" ];then
  if [ "$id" = "new" ];then
    view="get_new_incf.html.def"
  else
    view="get_rw_incf.html.def"
  fi
fi

cat ../descriptor/${view} | sed "s/^ *</</g" \
| sed "/%%common_menu/r ../descriptor/common_parts/common_menu" \
| sed "/%%common_menu/d" \
| sed "/%%databox_list/r ../tmp/$session/databox_list" \
| sed "s/%%databox_list//g"\
| sed "/%%dataset/r ../tmp/$session/dataset" \
| sed "s/%%databox/$databox/g" \
| sed "s/%%dataset//g"\
| sed "s/%%id/$id/g"\
| sed "s/%%session/$session/g"\
| sed "s/%%pin/$pin/g"\
| sed "s/%%pdls/session=$session\&pin=$pin\&req=get/g" \
| sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
