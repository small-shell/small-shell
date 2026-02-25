#!/bin/bash

# load env
. %%www/def/.env

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

  if [[ $param == remote_addr:* ]]; then
    remote_addr=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done


# mktmpdir
if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

# load post param
if [ -s %%www/tmp/${session}/command ];then
  if [ ! "$(grep $AWK %%www/tmp/${session}/command)" ];then
    command=$(cat %%www/tmp/${session}/command | $SED "s/%/{%%%%%%%%%%%%%%%%}/g" | $SED "s/_/{%%%%%%%}/g" | $SED "s/　/ /g" | $SED "s/ /_/g" \
    | $SED "s/\//{%%%%%}/g" \
    | $SED "s/,/{%%%%%%}/g" \
    | $SED "s/:/{%%%}/g" \
    | $SED "s/\&/{%%%%}/g" \
    | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | $SED "s/*/{%%%%%%%%%%%%%%%}/g" \
    | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | $SED "s/#/{%%%%%%%%%%%%%}/g" \
    | $SED "s/(/{%%%%%%%%}/g" \
    | $SED "s/)/{%%%%%%%%%}/g" \
    | $SED "s/\[/{%%%%%%%%%%}/g" \
    | $SED "s/\]/{%%%%%%%%%%%}/g")
  else
    command=$(cat %%www/tmp/${session}/command | $SED "s/%/{%%%%%%%%%%%%%%%%}/g" | $SED "s/_/{%%%%%%%}/g" | $SED "s/　/ /g" | $SED "s/ /_/g" \
    | $SED "s/\//{%%%%%}/g" \
    | $SED "s/:/{%%%}/g" \
    | $SED "s/\&/{%%%%}/g" \
    | $SED "s/#/{%%%%%%%%%%%%%}/g" \
    | $SED "s/(/{%%%%%%%%}/g" \
    | $SED "s/)/{%%%%%%%%%}/g" \
    | $SED "s/\[/{%%%%%%%%%%}/g" \
    | $SED "s/\]/{%%%%%%%%%%%}/g")
  fi
fi

if [ ! "$command" ];then
  command="head_-12"
fi

type_chk=$(echo "$command" | grep "{%%%%%%%%%%%%%}log")
if [ ! "$type_chk" ];then
  type=data
else
  type=log
  command=$(echo "$command" | $SED "s/_{%%%%%%%%%%%%%}log//g") 
fi

statistics_chk=$(echo "$command" | grep "{%%%%%%%%%%%%%}stats")
if [ "$statistics_chk" ];then
  statistics="yes"
  filters=$(echo "$command" | $SED "s/_{%%%%%%%%%%%%%}stats//g" | $SED "s/{%%%%%%%%%%%%%}stats//g" | $SED "s/_/,/g") 
  command=""
fi

# load permission
permission=$(${small_shell_path}/bin/meta get.attr:$user_name{permission})

# gen databox list for left menu
db_list="$databox $(${small_shell_path}/bin/meta get.databox)"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./base?session=$session&pin=$pin&databox=$db&req=console\">$db</option>"\
    >> %%www/tmp/${session}/databox_list
  fi
  ((count +=1 ))
done


# exec command and render HTML
if [ "$command" ];then
  #command=$(echo "$command" | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));")
  ${small_shell_path}/bin/DATA_shell session:$session pin:$pin \
  databox:$databox type:$type command:$command > %%www/tmp/${session}/exec
  commands=$(${small_shell_path}/bin/meta get.command | $SED "s/ /, /g")

  cat %%www/def/console.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%result/r %%www/tmp/${session}/exec" \
  | $SED "/%%result/d"\
  | $SED "/%%databox_list/r %%www/tmp/${session}/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%commands/${commands}/g" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu_${permission}" \
  | $SED "/%%common_menu/d"\
  | $SED "s/%%user/${user_name}/g"\
  | $SED "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | $SED "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | $SED "s/{%%%%%%%%%%%%%%%}/*/g"\
  | $SED "s/{%%%%%%%%%%%%%%}/$/g"\
  | $SED "s/{%%%%%%%%%%%%%}/#/g"\
  | $SED "s/{%%%%%%%%%%%%}/|/g"\
  | $SED "s/{%%%%%%%%%%%}/\]/g"\
  | $SED "s/{%%%%%%%%%%}/\[/g"\
  | $SED "s/{%%%%%%%%%}/)/g"\
  | $SED "s/{%%%%%%%%}/(/g"\
  | $SED "s/{%%%%%%%}/_/g"\
  | $SED "s/{%%%%%%}/,/g"\
  | $SED "s/{%%%%%}/\//g"\
  | $SED "s/{%%%%}/\&/g"\
  | $SED "s/{%%%}/:/g"\
  | $SED "s/%%remote_addr/${remote_addr}/g"\
  | $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g" 

elif [ "$statistics" ];then

  if [ "$filters" ];then
    ${small_shell_path}/bin/meta get.statistics:ls.${filters},db_${databox}{html_tag} > %%www/tmp/${session}/statistics 
    filters="filters:$filters"
  else 
    ${small_shell_path}/bin/meta get.statistics:ls.db_${databox}{html_tag} > %%www/tmp/${session}/statistics
  fi

  if [ ! -s %%www/tmp/${session}/statistics ];then
    echo "# No statistics data" > %%www/tmp/${session}/statistics
  fi

  commands=$(${small_shell_path}/bin/meta get.command | $SED "s/ /, /g")
  cat %%www/def/console_statistics.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%statistics/r %%www/tmp/${session}/statistics" \
  | $SED "/%%statistics/d"\
  | $SED "/%%databox_list/r %%www/tmp/${session}/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%commands/${commands}/g" \
  | $SED "s/%%filters/${filters}/g" \
  | $SED "/%%common_menu/r %%www/def/common_parts/common_menu_${permission}" \
  | $SED "/%%common_menu/d"\
  | $SED "s/%%user/${user_name}/g"\
  | $SED "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | $SED "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | $SED "s/{%%%%%%%%%%%%%%%}/*/g"\
  | $SED "s/{%%%%%%%%%%%%%%}/$/g"\
  | $SED "s/{%%%%%%%%%%%%%}/#/g"\
  | $SED "s/{%%%%%%%%%%%%}/|/g"\
  | $SED "s/{%%%%%%%%%%%}/\]/g"\
  | $SED "s/{%%%%%%%%%%}/\[/g"\
  | $SED "s/{%%%%%%%%%}/)/g"\
  | $SED "s/{%%%%%%%%}/(/g"\
  | $SED "s/{%%%%%%%}/_/g"\
  | $SED "s/{%%%%%%}/,/g"\
  | $SED "s/{%%%%%}/\//g"\
  | $SED "s/{%%%%}/\&/g"\
  | $SED "s/{%%%}/:/g"\
  | $SED "s/%%remote_addr/${remote_addr}/g"\
  | $SED "s/%%params/session=${session}\&pin=${pin}\&databox=${databox}/g"
fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
