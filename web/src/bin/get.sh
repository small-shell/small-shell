#!/bin/bash

# load small-shell conf
. %%www/descriptor/.small_shell_conf

# load query string param
for param in $(echo $@)
do

  if [[ $param == databox:* ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

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

done

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ "$id" = "" ];then
  echo "error: please set correct id"
fi

if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

# gen databox list for left menu
db_list="$databox $($META get.databox)"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./base?session=$session&pin=$pin&databox=$db&req=table\">$db</option>"\
    >> %%www/tmp/${session}/databox_list
  fi
  ((count +=1 ))
done

# -----------------
# Exec  command
# -----------------

# load permission
permission=$($META get.attr:$user_name{permission})

if [ ! "$duplicate" = "yes" ];then

  if [ ! "$permission" = "ro"  ];then

    # gen read/write datas
    $DATA_SHELL databox:$databox action:get id:$id keys:all format:html_tag > %%www/tmp/${session}/dataset

  else

    # gen read only datas
    $DATA_SHELL databox:$databox action:get id:$id keys:all format:none | grep -v hashid > %%www/tmp/${session}/dataset.0.1
    cat %%www/tmp/${session}/dataset.0.1 | $SED "s/^/<li><label>/g" | $SED "s/:/<\/label><pre>/1" | $SED "s/$/<\/pre><\/li>/g" \
    | $SED "s/<pre><\/pre>/<pre>-<\/pre>/g" | $SED "s/_%%enter_/\n/g" >> %%www/tmp/${session}/dataset

  fi

else

  # else means copying data
  keys=$($META get.key:$databox{all})
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
        echo "$data"  >> /var/www/tmp/${session}/dataset
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

# overwritten by markdown logic
if [[ $databox == images.db ]] && [[ ! "$id" == "new" ]];then
  app=$(echo "$databox" | $SED "s/.image//g")
  if [ "$permission" = "rw" ];then
    view="get_rw_incf_image.html.def"
  else
    view="get_ro_incf_image.html.def"
  fi 
fi  

# overwritten by clustering logic
if [ "$master" -a "$permission" = "rw" ];then
  if [ "$redirect" = "no" ];then
    if [ "$id" = "new" ];then
      view="get_new_master_failed.html.def"
    else
      view="get_rw_master_failed.html.def"
    fi
  fi
fi

# set class and text row for markdown 
if [[ $databox == *UI.md.def ]];then
   form_class=md-form-box
   text_area_row=14
else
   form_class=form-box
   text_area_row=10
fi

cat %%www/descriptor/${view} | $SED -r "s/^( *)</</1" \
| $SED "s/%%form-class/${form_class}/g" \
| $SED "s/%%text_area_row/${text_area_row}/g" \
| $SED "/%%common_menu/r %%www/descriptor/common_parts/common_menu" \
| $SED "/%%common_menu/d" \
| $SED "s/%%user/${user_name}/g"\
| $SED "/%%databox_list/r %%www/tmp/${session}/databox_list" \
| $SED "s/%%databox_list//g"\
| $SED "/%%dataset/r %%www/tmp/${session}/dataset" \
| $SED "s/%%databox/${databox}/g" \
| $SED "s/%%dataset//g"\
| $SED "s/%%id/${id}/g"\
| $SED "s/%%app/${app}/g"\
| $SED "s/%%session/${session}/g"\
| $SED "s/%%pin/${pin}/g"\
| $SED "s/%%pdls/session=${session}\&pin=${pin}\&req=get/g" \
| $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
