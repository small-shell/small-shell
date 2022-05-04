#!/bin/bash

#---------------------------------------------------------------------
# usage: dist.sh $APP $EXPORT_DIR
#----------------------------------------------------------------------

app=$1
export_dir=$2

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

# load base 
. $ROOT/web/base

main="$cgidir/../descriptor/${app}_main.html.def"
css="$cgidir/../descriptor/${app}.css.def"
descriptor="$cgidir/../descriptor"

if [ ! "$app" ];then
  echo "error: please input APP for exporting as static site, # dist.sh \$APP \$EXPORT_DIR"
  exit 1
fi

if [ ! "$export_dir" ];then
  echo "error: please input dir for exporting as static site # dist.sh \$APP \$EXPORT_DIRdist.sh \$APP \$EXPORT_DIR"
  exit 1
fi

if [ ! -f $main ];then
  echo "error: $app does not exist"
  exit 1
fi

if [ ! -d $export_dir ];then
  echo "error: $export_dir does not exist"
  exit 1
fi

# dist main
cat $main | sed "s/^ *</</g" \
| sed "/%%common_menu/r ${descriptor}/common_parts/${app}_common_menu" \
| sed "s/%%common_menu//g"\
| sed "s/<img src=\"../<img src=\"./g" \
| sed "s/${app}_css/${app}.css/g" > $export_dir/${app}_main.html

# dist css
cat $css > $export_dir/${app}.css


echo "# INFO #"
echo "-----------------------------------------------------------------------"
echo "Main page of $app is successfully exported to $export_dir as static site." 
echo "please copy both html and css to /var/www/html or other static folder"
echo "-----------------------------------------------------------------------"

exit 0
