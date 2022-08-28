#!/bin/bash

#---------------------------------------------------------------------
# usage:    bat_import.sh $authkey $databox $import_file 
#----------------------------------------------------------------------

authkey=$1
databox=$2
import_file=$3

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be small-shell"
  exit 1
fi

if [ ! $import_file ];then
  echo "error: import file does not exist"
  exit 1
fi

# global conf load
SCRIPT_DIR=`dirname $0`
 . ${SCRIPT_DIR}/../../global.conf

# authentication
if [ "$authkey" ];then
  auth_req=`$ROOT/bin/auth key_auth:${authkey} remote_addr:localhost`
  session=`echo $auth_req | $AWK -F "," '{print $2}' | $AWK -F ":" '{print $2}'`
  pin=`echo $auth_req | $AWK -F "," '{print $3}' | $AWK -F ":" '{print $2}'`
fi

if [ ! "$session" ];then
  echo "error: authkey must be wrong"
  exit 1
fi

# import 
nice -n 19 ${ROOT}/bin/data_import $import_file $databox $session $pin localhost &
sleep 1

exit 0
