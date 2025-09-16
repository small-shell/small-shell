#!/bin/bash

#---------------------------------------------------------
# usage: del_datasets.sh $authkey $databox $list_file
# list_file must be list of ID of data
#---------------------------------------------------------

authkey=$1
databox=$2
list_file=$3

WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be small-shell"
  exit 1
fi

if [ ! -f "$list_file" ];then
  echo "error: list file is not existing"
  exit 1
fi

# global conf load
SCRIPT_DIR=$(dirname $0)
 . ${SCRIPT_DIR}/../../global.conf

# authentication
if [ "$authkey" ];then
  auth_req=$(${ROOT}/bin/auth key_auth:${authkey} remote_addr:localhost user_agent:del_datasets)
  session=$(echo "$auth_req" | $AWK -F "," '{print $2}' | $AWK -F ":" '{print $2}')
  pin=$(echo "$auth_req" | $AWK -F "," '{print $3}' | $AWK -F ":" '{print $2}')
fi

if [ ! "$session" ];then
  echo "error: authkey must be wrong"
  exit 1
fi

primary_key_name=$(cat ${ROOT}/databox/${databox}/def/col1 | grep "^name=\"" | $AWK -F "name=" '{print $2}' | $SED "s/\"//g")
if [ "$primary_key_name" = "hashid" ];then
  hashid=yes
fi

# exec delete 
for id in $(cat $list_file)
do
  if [ ! "$hashid" = "yes" ];then
    org_id=$id
    id=$(echo "$id" | $SHASUM | $AWK '{print $1}')
    echo "id:$org_id is $id internally"
  fi
  ${ROOT}/bin/DATA_shell session:$session pin:$pin databox:$databox action:del id:$id format:none
done

exit 0
