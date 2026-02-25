#!/bin/bash

# Target databox and keys
databox=%%databox
keys=all

# load small-shell conf
. %%www/def/.env

# load query string param
for param in $(echo $@)
do

  if [[ $param == session:* ]]; then
    session=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == pin:* ]]; then
    pin=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == user_name:* ]]; then
    user_name=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == id:* ]]; then
    id=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == duplicate:* ]]; then
    duplicate=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [ "$master" ];then
    if [[ $param == redirect* ]];then
      redirect=$(echo "$param" | $AWK -F":" '{print $2}')
    fi
  fi

  # handle calendar events
  if [[ $param == *.events ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
    databox=$databox
  fi

done

if [ ! "$id"  ];then
  id="new"
fi

if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%app"

# load permission
if [ ! "$user_name" = "guest" ];then
  permission=$($META get.attr:%%app/${user_name}{permission})
else
  permission="ro"
fi

if [ ! "$duplicate" = "yes" ];then
  if [ ! "$permission" = "ro"  ];then

    # gen read/write datas
    $DATA_SHELL databox:$databox action:get id:$id keys:$keys format:html_tag > %%www/tmp/${session}/dataset

  else

    # gen read only datas
    $DATA_SHELL databox:$databox action:get id:$id keys:$keys format:none | grep -v hashid > %%www/tmp/${session}/dataset.0.1
    cat %%www/tmp/${session}/dataset.0.1 | $SED "s/^/<li><label>/g" | $SED "s/:/<\/label><pre>/1" | $SED "s/$/<\/pre><\/li>/g" \
    | $SED "s/<pre><\/pre>/<pre>-<\/pre>/g" | $SED "s/_%%enter_/\n/g" >> %%www/tmp/${session}/dataset

  fi

else

  # else means copying data
  if [ "$keys" = "all" ];then
    keys=$($META get.key:$databox{all})
  fi
  primary_key=$($META get.key:$databox{primary})

  $DATA_SHELL databox:$databox \
  action:get id:new key:$primary_key format:html_tag > %%www/tmp/${session}/dataset

  for key in $keys
  do
    # gen %%data by conpying
    if [ ! "$primary_key" = "$key" ];then
      data=$($DATA_SHELL databox:$databox \
      action:get id:$id key:$key format:html_tag)
      file_chk=$(echo "$data" | grep "<div class=\"file_form\">" )

      if [ ! "$file_chk" ];then
        echo "$data"  >> %%www/tmp/${session}/dataset
      else
        $DATA_SHELL databox:$databox \
        action:get id:new key:$key format:html_tag  >> %%www/tmp/${session}/dataset
      fi
    fi
  done
  id=new

fi

# error check
error_chk=$(cat %%www/tmp/${session}/dataset | grep "^error:")

# form type check
form_chk=$($META chk.form:$databox)

# set view
if [ "$error_chk" ];then
  view="%%app_get_err.html.def"

elif [ "$permission"  = "ro" ];then
  view="%%app_get_ro.html.def"

elif [ "$form_chk" = "urlenc" ];then
  if [ "$id" = "new" ];then
    view="%%app_get_new.html.def"
  else
    view="%%app_get_rw.html.def"
  fi
elif [ "$form_chk" = "multipart" ];then
  if [ "$id" = "new" ];then
    view="%%app_get_new_incf.html.def"
  else
    view="%%app_get_rw_incf.html.def"
  fi
fi

# overwritten by clustering logic
if [ "$master" -a "$permission" = "rw" ];then
  if [ "$redirect" = "no" ];then
    if [ "$id" = "new" ];then
      view="%%app_get_new_master_failed.html.def"
    else
      view="%%app_get_rw_master_failed.html.def"
    fi
  fi
fi

# render HTML
cat %%www/def/${view} | $SED -r "s/^( *)</</1" \
| $SED "/%%common_menu/r %%www/def/common_parts/%%app_common_menu" \
| $SED "/%%common_menu/d" \
| $SED "s/%%user/${user_name}/g"\
| $SED "/%%dataset/r %%www/tmp/${session}/dataset" \
| $SED "s/%%dataset//g"\
| $SED "/%%history/r %%www/tmp/${session}/history" \
| $SED "s/%%history//g"\
| $SED "s/%%id/${id}/g" \
| $SED "s/%%pdls/session=${session}\&pin=${pin}\&req=get/g" \
| $SED "s/%%session/session=${session}\&pin=${pin}/g" \
| $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"


if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
