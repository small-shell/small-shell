#!/bin/bash

#---------------------------------------------------------
# usage: del_databox.sh $databox
#---------------------------------------------------------

databox=$1

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# global conf load
SCRIPT_DIR=`dirname $0`
 . ${SCRIPT_DIR}/../../global.conf

# web/basee load
. ${ROOT}/web/base

# error handling
if [ ! "$databox" ];then
  echo "error: databox name is null" 
  exit 1
fi

if [ ! -d $ROOT/databox/${databox} ];then
  echo "error: there is no databox{${databox}}"
  exit 1
fi

chk_app=`grep "databox=${databox}" ${www}/bin/*_get.sh  | xargs basename -a | $AWK -F "_get.sh" '{print $1}' \
| $SED -z "s/\n/,/g" | $SED "s/,$//g"`

if [ "$chk_app" ];then
  echo "warn: ${databox} is used by Scratch APP {$chk_app}, please delete APP first by using del_app.sh"
  exit 1
fi

# delete databox
rm -rf $ROOT/databox/${databox}

if [ $? -eq 0 ];then
  echo "databox{${databox}} has been deleted. "
else
  echo "error: failed to delete databox" 
  exit 1
fi

exit 0
