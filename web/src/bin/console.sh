#!/bin/bash

# load small-shell conf
. ../descriptor/.small_shell_conf

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == remote_addr:* ]]; then
    remote_addr=`echo $param | $AWK -F":" '{print $2}'`
  fi

done


# mktmpdir
if [ ! -d ../tmp/$session ];then
  mkdir ../tmp/$session
fi

# load post param
if [ -s ../tmp/$session/command ];then
  if [ ! "`grep $AWK ../tmp/$session/command`" ];then
    command=`cat ../tmp/$session/command | $SED "s/%/{%%%%%%%%%%%%%%%%}/g" | $SED "s/_/{%%%%%%%}/g" | $SED "s/　/ /g" | $SED "s/ /_/g" \
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
    | $SED "s/\]/{%%%%%%%%%%%}/g"`
  else
    command=`cat ../tmp/$session/command | $SED "s/%/{%%%%%%%%%%%%%%%%}/g" | $SED "s/_/{%%%%%%%}/g" | $SED "s/　/ /g" | $SED "s/ /_/g" \
    | $SED "s/\//{%%%%%}/g" \
    | $SED "s/:/{%%%}/g" \
    | $SED "s/\&/{%%%%}/g" \
    | $SED "s/#/{%%%%%%%%%%%%%}/g" \
    | $SED "s/(/{%%%%%%%%}/g" \
    | $SED "s/)/{%%%%%%%%%}/g" \
    | $SED "s/\[/{%%%%%%%%%%}/g" \
    | $SED "s/\]/{%%%%%%%%%%%}/g"`
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
  command=`echo "$command" | $SED "s/_{%%%%%%%%%%%%%}log//g"` 
fi

statistics_chk=`echo "$command" | grep "{%%%%%%%%%%%%%}stats"`
if [ "$statistics_chk" ];then
  statistics="yes"
  filters=`echo "$command" | $SED "s/_{%%%%%%%%%%%%%}stats//g" | $SED "s/{%%%%%%%%%%%%%}stats//g" | $SED "s/_/,/g"` 
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
  #command=`echo $command | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));"`
  sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin \
  databox:$databox type:$type command:$command > ../tmp/$session/exec
  commands=`sudo -u small-shell ${small_shell_path}/bin/meta get.command | $SED "s/ /, /g"`

  cat ../descriptor/console.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%result/r ../tmp/$session/exec" \
  | $SED "/%%result/d"\
  | $SED "/%%databox_list/r ../tmp/$session/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%user/$user_name/g"\
  | $SED "s/%%commands/$commands/g" \
  | $SED "/%%common_menu/r ../descriptor/common_parts/common_menu_${permission}" \
  | $SED "/%%common_menu/d"\
  | $SED "/%%footer/r ../descriptor/common_parts/footer" \
  | $SED "/%%footer/d"\
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
  | $SED "s/%%remote_addr/$remote_addr/g"\
  | $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g" 

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

  commands=`sudo -u small-shell ${small_shell_path}/bin/meta get.command | $SED "s/ /, /g"`
  cat ../descriptor/console.statistics.html.def | $SED -r "s/^( *)</</1" \
  | $SED "/%%statistics/r ../tmp/$session/statistics" \
  | $SED "/%%statistics/d"\
  | $SED "/%%databox_list/r ../tmp/$session/databox_list" \
  | $SED "s/%%databox_list//g"\
  | $SED "s/%%user/$user_name/g"\
  | $SED "s/%%commands/$commands/g" \
  | $SED "s/%%filters/$filters/g" \
  | $SED "/%%common_menu/r ../descriptor/common_parts/common_menu_${permission}" \
  | $SED "/%%common_menu/d"\
  | $SED "/%%footer/r ../descriptor/common_parts/footer" \
  | $SED "/%%footer/d"\
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
  | $SED "s/%%remote_addr/$remote_addr/g"\
  | $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g"
fi

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
