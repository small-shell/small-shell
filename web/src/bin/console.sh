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

  if [[ $param == remote_addr:* ]]; then
    remote_addr=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# mktmpdir
if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# load post param
if [ -s ../tmp/$session/command ];then
  if [ ! "`grep awk ../tmp/$session/command`" ];then
    command=`cat ../tmp/$session/command | sed "s/%/{%%%%%%%%%%%%%%%%}/g" | sed "s/_/{%%%%%%%}/g" | sed "s/　/ /g" | sed "s/ /_/g" \
    | sed "s/\//{%%%%%}/g" \
    | sed "s/,/{%%%%%%}/g" \
    | sed "s/:/{%%%}/g" \
    | sed "s/\&/{%%%%}/g" \
    | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | sed "s/*/{%%%%%%%%%%%%%%%}/g" \
    | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | sed "s/#/{%%%%%%%%%%%%%}/g" \
    | sed "s/(/{%%%%%%%%}/g" \
    | sed "s/)/{%%%%%%%%%}/g" \
    | sed "s/\[/{%%%%%%%%%%}/g" \
    | sed "s/\]/{%%%%%%%%%%%}/g"`
  else
    command=`cat ../tmp/$session/command | sed "s/%/{%%%%%%%%%%%%%%%%}/g" | sed "s/_/{%%%%%%%}/g" | sed "s/　/ /g" | sed "s/ /_/g" \
    | sed "s/\//{%%%%%}/g" \
    | sed "s/:/{%%%}/g" \
    | sed "s/\&/{%%%%}/g" \
    | sed "s/#/{%%%%%%%%%%%%%}/g" \
    | sed "s/(/{%%%%%%%%}/g" \
    | sed "s/)/{%%%%%%%%%}/g" \
    | sed "s/\[/{%%%%%%%%%%}/g" \
    | sed "s/\]/{%%%%%%%%%%%}/g"`
  fi
fi

if [ ! "$command" ];then
  command="head_-12"
fi

type_chk=`echo "$command" | grep "{%%%%%%%%%%%%%}log"`
if [ ! "$type_chk" ];then
  type=data
else
  type=log
  command=`echo "$command" | sed "s/_{%%%%%%%%%%%%%}log//g"` 
fi

statistics_chk=`echo "$command" | grep "{%%%%%%%%%%%%%}stats"`
if [ "$statistics_chk" ];then
  statistics="yes"
  filters=`echo "$command" | sed "s/_{%%%%%%%%%%%%%}stats//g" | sed "s/{%%%%%%%%%%%%%}stats//g" | sed "s/_/,/g"` 
  command=""
fi

# load permission
permission=`${small_shell_path}/bin/meta get.attr:$user_name{permission}`

# gen databox list for left menu
db_list="$databox `${small_shell_path}/bin/meta get.databox`"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./shell.app?session=$session&pin=$pin&databox=$db&req=console\">DataBox:$db</option>"\
    >> ../tmp/$session/databox_list
  fi
  ((count +=1 ))
done


# exec command and render HTML
if [ "$command" ];then
  #command=`echo $command | php -r "echo preg_quote(file_get_contents('php://stdin'));"`
  sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin \
  databox:$databox type:$type command:$command > ../tmp/$session/exec
  commands=`sudo -u small-shell ${small_shell_path}/bin/meta get.command | sed "s/ /, /g"`

  cat ../descriptor/console.html.def | sed "s/^ *</</g" \
  | sed "/%%result/r ../tmp/$session/exec" \
  | sed "/%%result/d"\
  | sed "/%%databox_list/r ../tmp/$session/databox_list" \
  | sed "s/%%databox_list//g"\
  | sed "s/%%user/$user_name/g"\
  | sed "s/%%commands/$commands/g" \
  | sed "/%%common_menu/r ../descriptor/common_parts/common_menu_${permission}" \
  | sed "/%%common_menu/d"\
  | sed "/%%footer/r ../descriptor/common_parts/footer" \
  | sed "/%%footer/d"\
  | sed "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | sed "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | sed "s/{%%%%%%%%%%%%%%%}/*/g"\
  | sed "s/{%%%%%%%%%%%%%%}/$/g"\
  | sed "s/{%%%%%%%%%%%%%}/#/g"\
  | sed "s/{%%%%%%%%%%%%}/|/g"\
  | sed "s/{%%%%%%%%%%%}/\]/g"\
  | sed "s/{%%%%%%%%%%}/\[/g"\
  | sed "s/{%%%%%%%%%}/)/g"\
  | sed "s/{%%%%%%%%}/(/g"\
  | sed "s/{%%%%%%%}/_/g"\
  | sed "s/{%%%%%%}/,/g"\
  | sed "s/{%%%%%}/\//g"\
  | sed "s/{%%%%}/\&/g"\
  | sed "s/{%%%}/:/g"\
  | sed "s/%%remote_addr/$remote_addr/g"\
  | sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g" 

elif [ "$statistics" ];then

  if [ "$filters" ];then
    sudo -u small-shell ${small_shell_path}/bin/meta get.statistics:ls.${filters}{html_tag} > ../tmp/$session/statistics 
    filters="filters:$filters"
  else 
    sudo -u small-shell ${small_shell_path}/bin/meta get.statistics:ls.db_${databox}{html_tag} > ../tmp/$session/statistics
  fi

  if [ ! -s ../tmp/$session/statistics ];then
    echo "! statistics will be started once you make statistics job" > ../tmp/$session/statistics
  fi

  commands=`sudo -u small-shell ${small_shell_path}/bin/meta get.command | sed "s/ /, /g"`
  cat ../descriptor/console.statistics.html.def | sed "s/^ *</</g" \
  | sed "/%%statistics/r ../tmp/$session/statistics" \
  | sed "/%%statistics/d"\
  | sed "/%%databox_list/r ../tmp/$session/databox_list" \
  | sed "s/%%databox_list//g"\
  | sed "s/%%user/$user_name/g"\
  | sed "s/%%commands/$commands/g" \
  | sed "s/%%filters/$filters/g" \
  | sed "/%%common_menu/r ../descriptor/common_parts/common_menu_${permission}" \
  | sed "/%%common_menu/d"\
  | sed "/%%footer/r ../descriptor/common_parts/footer" \
  | sed "/%%footer/d"\
  | sed "s/{%%%%%%%%%%%%%%%%%}/'/g"\
  | sed "s/{%%%%%%%%%%%%%%%%}/%/g"\
  | sed "s/{%%%%%%%%%%%%%%%}/*/g"\
  | sed "s/{%%%%%%%%%%%%%%}/$/g"\
  | sed "s/{%%%%%%%%%%%%%}/#/g"\
  | sed "s/{%%%%%%%%%%%%}/|/g"\
  | sed "s/{%%%%%%%%%%%}/\]/g"\
  | sed "s/{%%%%%%%%%%}/\[/g"\
  | sed "s/{%%%%%%%%%}/)/g"\
  | sed "s/{%%%%%%%%}/(/g"\
  | sed "s/{%%%%%%%}/_/g"\
  | sed "s/{%%%%%%}/,/g"\
  | sed "s/{%%%%%}/\//g"\
  | sed "s/{%%%%}/\&/g"\
  | sed "s/{%%%}/:/g"\
  | sed "s/%%remote_addr/$remote_addr/g"\
  | sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
