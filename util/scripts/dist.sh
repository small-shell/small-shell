#!/bin/bash

#---------------------------------------------------------------------
# usage: dist.sh $APP $EXPORT_DIR
#----------------------------------------------------------------------

app=$1
export_dir=$2
export_dir=`echo $export_dir | $SED "s/\/$//g"`

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
cat $main | $SED "s/^ *</</g" \
| $SED "/%%common_menu/r ${descriptor}/common_parts/${app}_common_menu" \
| $SED "s/%%common_menu//g"\
| $SED "s/<img src=\"../<img src=\"./g" \
| $SED "s/${app}_css/${app}.css/g" > ${export_dir}/index.html

metalinks=`grep -e %%session -e %%params $export_dir/index.html`

# dist css
cat $css > $export_dir/${app}.css


echo "# INFO #"
echo "---------------------------------------------------------------------------------------"
echo ""
echo "Main page of $app is successfully exported to $export_dir as static site." 
echo "please copy both html and css to /var/www/html or other static folder"

if [ "$metalinks" ];then
  echo ""
  echo "!! need to modify following metalinks when you distribute ${export_dir}/index.html to static folder"
  echo "$metalinks"
  echo ""
fi
echo "---------------------------------------------------------------------------------------"

exit 0
