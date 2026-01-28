#!/bin/bash

#---------------------------------------------------------
# usage: del_app.sh $app
#---------------------------------------------------------

app=$1

WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# global conf load
SCRIPT_DIR=$(dirname $0)
 . ${SCRIPT_DIR}/../../global.conf

# web/basee load
. ${ROOT}/web/base

# error handling
if [ ! "$app" ];then
  echo "error: app name is null" 
  exit 1
fi

if [ "$app" = "base" -o "$app" = "api" -o "$app" = "e-cron" ];then
  echo "error: $app is part of Base App"
  exit 1
fi

ls ${www}/bin/${app}_get.sh >/dev/null 2>&1
if [ ! $? = 0 ];then
  echo "error: there is no app{$app}"
  exit 1
fi

chk_app=$(cat ${www}/bin/${app}_get.sh | grep DATA_SHELL | grep app:  | $AWK -F "app:" '{print $2}' | $SED "s/\"//g")
if [ ! "$chk_app" = "$app" ];then
  parent_app=$chk_app
fi

# rm actionscript
rm ${www}/bin/${app}_*

# rm def and index
rm ${www}/def/${app}_*

if [ -f ${www}/def/common_parts/${app}_common_menu ];then
  rm ${www}/def/common_parts/${app}_common_menu
fi

if [ -f ${www}/html/${app}/index.html ];then
  rm ${www}/html/${app}/index.html
fi

# update controller
if [ "$parent_app" ];then

  if [ -f ${www}/cgi-bin/${parent_app} ];then
    # load routing
    routing=$(cat ${www}/cgi-bin/${parent_app} | grep ${app}_)
    # show meesage
    echo "App{${app}} has been deleted, please edit parebnt App controller"
    echo "target file: ${www}/cgi-bin/${parent_app}"
    echo "---------------------------------------------------------------------"
    echo "$routing"
    echo "---------------------------------------------------------------------"
    echo "also it's recommended to update portal menu in ${parent_app}.UI.md.def on Base App"
  else
    echo "App{${app}} has been deleted"
  fi
  
else
  # rm auth and controller
  if [ -f ${www}/cgi-bin/auth.${app} ];then
    rm ${www}/cgi-bin/auth.${app}
  fi
  rm ${www}/cgi-bin/${app}

  # rm databoxes
  rm -rf ${ROOT}/databox/${app}.UI.md.def
  rm -rf ${ROOT}/databox/${app}.events

  # rm static page
  rm -rf ${static_dir}/${app}
  rm ${static_dir}/${app}.css

  # show meesage
  echo "App{${app}} has been deleted"

fi

exit 0
