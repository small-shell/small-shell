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

  if [[ $param == filter:* ]]; then
    filter=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ ! -d %%www/tmp/${session} ];then
  mkdir %%www/tmp/${session}
fi

if [[ $filter == *{*} ]]; then
  filter_key=$(echo "$filter" | $AWK -F "{" '{print $1}')
  filter_word=$(echo "$filter" | $AWK -F "{" '{print $2}' | $SED "s/}//g" | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
  | $SED "s/_/{%%%%%%%}/g" | $SED "s/\//{%%%%%}/g"  \
  | $SED "s/(/{%%%%%%%%}/g" | $SED "s/)/{%%%%%%%%%}/g" | $SED "s/\[/{%%%%%%%%%%}/g" | $SED "s/\]/{%%%%%%%%%%%}/g" \
  | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" | $SED "s/*/{%%%%%%%%%%%%%%%}/g" | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
  | $SED "s/,/{%%%%%%}/g"  | $SED "s/#/{%%%%%%%%%%%%%}/g" |  $SED "s/\&/{%%%%}/g" | $SED "s/:/{%%%}/g" | $SED "s/　/ /g" | $SED "s/ /,/g"\
  | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));")
  filter_table="$filter_key{$filter_word}"
else
  filter_table=$(echo "$filter"  | $SED "s/%/{%%%%%%%%%%%%%%%%}/g" | $SED "s/_/{%%%%%%%}/g" | $SED "s/\//{%%%%%}/g" | $SED "s/,/{%%%%%%}/g" \
  | $SED "s/\[/{%%%%%%%%%%}/g" | $SED "s/\]/{%%%%%%%%%%%}/g"| $SED "s/(/{%%%%%%%%}/g" | $SED "s/)/{%%%%%%%%%}/g" | $SED "s/|/{%%%%%%%%%%%%}/g" \
  | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" | $SED "s/*/{%%%%%%%%%%%%%%%}/g" | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
  | $SED "s/#/{%%%%%%%%%%%%%}/g" |  $SED "s/\&/{%%%%}/g" | $SED "s/:/{%%%}/g" | $SED "s/　/ /g" | $SED "s/ /,/g" \
  | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));")
fi

# -----------------
# Exec command
# -----------------

# render csv
if [ ! "$filter" = "%%header" ];then

  if [ "$filter" = "-" ];then
    $DATA_SHELL databox:$databox command:show_all format:csv > %%www/tmp/${session}/csv
  else
    $DATA_SHELL databox:$databox command:show_all[filter=${filter_table}] format:csv > %%www/tmp/${session}/csv
  fi

  cat %%www/tmp/${session}/csv \
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
  | $SED "s/{%%%}/:/g"
else
  ${small_shell_path}/bin/meta get.header:$databox{csv}
fi

if [ "$session" ];then
  rm -rf %%www/tmp/${session}
fi

exit 0
