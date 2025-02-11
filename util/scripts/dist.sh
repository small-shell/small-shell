#!/bin/bash

#---------------------------------------------------------------------
# usage: dist.sh $APP
#----------------------------------------------------------------------

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

app=$1

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# gen tmpdir
random=$RANDOM
while [ -d $ROOT/tmp/gen/$random ]
do
 sleep 0.01
 count=`expr $count + 1`
 if [ $count -eq 100 ];then
   echo "error: something is wrong"
   exit 1
 fi
 random=$RANDOM
done
mkdir $ROOT/util/scripts/tmp/$random
tmp_dir="$ROOT/util/scripts/tmp/$random"

# load base 
. $ROOT/web/base

main="$cgidir/../descriptor/${app}_main.html.def"
css="$cgidir/../descriptor/${app}.css.def"
descriptor="$cgidir/../descriptor"

if [ ! "$app" ];then
  echo "error: please input APP for exporting as static site, # dist.sh \$APP \$EXPORT_DIR"
  exit 1
fi

if [ ! -f $main ];then
  echo "error: $app does not exist"
  exit 1
fi

# dist main
cat $main | $SED "s/^ *</</g" \
| $SED "/%%common_menu/r ${descriptor}/common_parts/${app}_common_menu" \
| $SED "s/%%common_menu//g"\
| $SED "s/${app}_css/${app}.css/g" > ${tmp_dir}/index.html

# replace images
grep "<img src=" ${tmp_dir}/index.html | grep images > ${tmp_dir}/.images
. ${SCRIPT_DIR}/.authkey

while read line
do
  id=`echo "$line" | $AWK -F "images/" '{print $2}' | $AWK -F "." '{print $1}'`
  file_name=`sudo -u small-shell ${ROOT}/bin/DATA_shell authkey:${authkey} \
             databox:images.db id:${id} remote_addr:localhost key:image action:get format:none \
             | $SED "s/image://g" | $AWK -F "#" '{print $1}'`
  file_type=`echo $file_name | awk -F "." '{print $NF}'`

  (cd ${tmp_dir} && sudo -u small-shell $ROOT/bin/dl authkey:${authkey} databox:images.db id:${id} remote_addr:localhost > ${file_name})
  cat ${tmp_dir}/index.html | $SED -r "s#<img src=\"(.*)/images/${id}.${file_type}#<img src=\"./${file_name}#g" > ${tmp_dir}/.index.html.tmp
  cat ${tmp_dir}/.index.html.tmp > ${tmp_dir}/index.html

done < ${tmp_dir}/.images

# dist css
cat $css > $tmp_dir/${app}.css
rm ${tmp_dir}/.index.html.tmp
rm ${tmp_dir}/.images
mv $tmp_dir ${SCRIPT_DIR}/tmp/${app}
(cd ${SCRIPT_DIR}/tmp/ && tar cvfz ${app}.tar.gz ${app})
mv ${SCRIPT_DIR}/tmp/${app}.tar.gz ${www}/html/${app}.tar.gz
rm -rf ${SCRIPT_DIR}/tmp/${app}

echo "============================================================"
if [ "$index_url" ];then
  echo "APP is successfully exported, download linnk is here"
  echo "${index_url}${app}.tar.gz"
else
  echo "APP is successfully exported to html directory"
  echo "${www}/html/${app}.tar.gz"
fi
echo "============================================================"

exit 0
