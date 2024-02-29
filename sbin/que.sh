#!/bin/bash

databox=$1
id=$2
updated_keys=$3
session=$4
pin=$5
flag=$6
app=$7

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be shell master"
  exit 1
fi

## global conf load
SCRIPT_DIR=`dirname $0`
 . ${SCRIPT_DIR}/../global.conf

# authorized session check
if [ -f $ROOT/tmp/que/$session ];then
  user=`cat $ROOT/tmp/que/$session | $AWK -F ":" '{print $1}'`

  if [ "$app" = "shell.app" ];then
    # check token
    tokencheck=`echo "${user}:${pin}" | $SHASUM | $AWK '{print $1}'`
  else
    # check app token
    tokencheck=`echo "${app}:${user}:${pin}" | $SHASUM | $AWK '{print $1}'`
  fi

  if [ ! "$session" = "$tokencheck" ];then
    echo "error: pin is wrong, you need authentication"
    exit 1
  fi
  if [ "$session" ];then
    rm $ROOT/tmp/que/$session
  fi
else
  echo "error: you need authentication"
  exit 1
fi

# check lock file
lock=no
exec 4>$ROOT/tmp/exec/lock
$FLOCK -n 4
if [ $? -eq 0 ];then
  lock=yes  
fi

count=0
while [ "$lock" = "no" ]
do
 sleep 0.1
 $FLOCK -n 4
 if [ $? -eq 0 ];then
   lock=yes  
 fi
 ((count += 1))
 if [ "$count" -gt 200000 ];then
   # logging error log
   echo "`date +%Y-%m-%d` `date +%T` error failed to update index by que.sh" >> $ROOT/databox/$databox/error.log
   exit 1
 fi
done

if [ "$flag" = "set" -o "$flag" = "delcol" -o "$flag" = "addcol" ];then
  primary_key=`grep "^name=" $ROOT/databox/${databox}/def/col1 | $AWK -F"=" '{print $2}' | $SED "s/\"//g"`
  primary_key_value=`cat ${ROOT}/databox/${databox}/data/${id}/${primary_key}`
fi

if [ "$flag" = "del" ];then
  primary_key=`grep "^name=" $ROOT/databox/${databox}/def/col1 | $AWK -F"=" '{print $2}' | $SED "s/\"//g"`
  primary_key_value=`cat ${ROOT}/databox/${databox}/data/${id}.detouched/${primary_key}`
  rm -rf ${ROOT}/databox/${databox}/data/${id}.detouched
fi

# logging
if [ "$flag" = "set" -o "$flag" = "addcol" ];then
  for updated_key in `echo $updated_keys | $SED "s/,/ /g"`
  do

    if [ -f ${ROOT}/databox/${databox}/data/${id}/${updated_key} ];then
      value=`cat ${ROOT}/databox/${databox}/data/${id}/${updated_key} | $SED -z "s/\n//g"`
    fi

    if [ ! "$value" ];then
      value="-"
    fi

    timestamp="`date +%Y-%m-%d` `date +%T`"
    log="${timestamp},user:${user} set key:${updated_key} value:${value}" 
    log_dump="${timestamp} user:${user} primary_key:$primary_key_value updated_key:${updated_key} value:${value} #id:$id" 
    echo "$log" >> $ROOT/databox/$databox/log/$id/history 
    echo "$log_dump" >> $ROOT/databox/$databox/log.dump

    # gen hash
    hash=`echo "$log_dump" | $SHASUM | $AWK '{print $1}'`

    # update hash chain
    last_hash=`grep synthesis_hash $ROOT/databox/$databox/hashchain | tail -1 | $AWK -F ":" '{print $2}'`
    synthesis_hash=` echo ${last_hash}${hash} | $SHASUM | $AWK '{print $1}'`
    echo "`date +%Y-%m-%d` `date +%T` id             :$id" >> $ROOT/databox/$databox/hashchain
    echo "`date +%Y-%m-%d` `date +%T` hash           :$hash" >> $ROOT/databox/$databox/hashchain
    echo "`date +%Y-%m-%d` `date +%T` synthesis_hash :$synthesis_hash" >> $ROOT/databox/$databox/hashchain

  done
fi

if [ "$flag" = "del" -o "$flag" = "delcol" ];then
  for updated_key in `echo $updated_keys | $SED "s/,/ /g"`
  do
    value="null(detouched)"
    timestamp="`date +%Y-%m-%d` `date +%T`"
    log="${timestamp},user:${user} set key:${updated_key} value:${value}" 
    log_dump="${timestamp} user:${user} primary_key:$primary_key_value updated_key:${updated_key} value:${value} #id:$id" 
    echo "$log" >> $ROOT/databox/$databox/log/$id/history 
    echo "$log_dump" >> $ROOT/databox/$databox/log.dump

    # gen hash
    hash=`echo "$log_dump" | $SHASUM | $AWK '{print $1}'`

    # update hash chain
    last_hash=`grep synthesis_hash $ROOT/databox/$databox/hashchain | tail -1 | $AWK -F ":" '{print $2}'`
    synthesis_hash=` echo ${last_hash}${hash} | $SHASUM | $AWK '{print $1}'`
    echo "`date +%Y-%m-%d` `date +%T` id             :$id" >> $ROOT/databox/$databox/hashchain
    echo "`date +%Y-%m-%d` `date +%T` hash           :$hash" >> $ROOT/databox/$databox/hashchain
    echo "`date +%Y-%m-%d` `date +%T` synthesis_hash :$synthesis_hash" >> $ROOT/databox/$databox/hashchain
  done
fi

# gen csv data
if [ "$flag" = "set" -o "$flag" = "addcol" -o "$flag" = "delcol" ];then
  csv_data=""
  for col in `ls $ROOT/databox/${databox}/def/col* | sort -V | xargs basename -a`
  do
    key=`grep "^name=" $ROOT/databox/${databox}/def/$col | $AWK -F"=" '{print $2}' | $SED "s/\"//g" | $SED "s/ //g"`
    type=`grep "^type=" $ROOT/databox/${databox}/def/$col | $AWK -F"=" '{print $2}' | $SED "s/\"//g" | $SED "s/ //g"` 

   if [ "$csv_data" ];then
     if [ -f "${ROOT}/databox/${databox}/data/${id}/${key}" ];then

       if [ $type = "url" ];then
         value=`cat ${ROOT}/databox/${databox}/data/${id}/${key}`
         if [ "$value" ];then
           value=`echo "$value" | $SED  "s/^/a%% href=\"/g" \
           | $SED "s/$/\" target=\"_blank\" rel=\"noopener noreferrer\">url%%a/g"`
         fi
       elif [ $type = "file" ];then
         value=`cat ${ROOT}/databox/${databox}/data/${id}/${key}`
         if [ "$value" ];then
           file_name=`echo "$value" | $SED -r "s/ #size(.*)//g"`
           value=`echo "$value" | $SED "s/^/a%% href=\".\/shell.app?%%params\&req=file\&id=$id\" download=\"$file_name\">/g" \
           | $SED "s/$/%%a/g"`
         fi
       elif [ $type = "checkbox" ];then
         value=`cat ${ROOT}/databox/${databox}/data/${id}/${key} | $SED "s/$/,/g" | $SED -z "s/\n//g" | $SED "s/,$//g" | $SED "s/^,//g"`
       elif [ $type = "pdls" ];then
         addkvl_chk=`grep "^addkvl=" $ROOT/databox/${databox}/def/$col` 
         if [ ! "$addkvl_chk" ];then
           value=`cat ${ROOT}/databox/${databox}/data/${id}/${key}`
         else
           value=`cat ${ROOT}/databox/${databox}/data/${id}/${key} | $AWK -F "#" '{print $NF}'`
         fi
       else
         value=`cat ${ROOT}/databox/${databox}/data/${id}/${key}`
       fi

       if [ ! "$value" ];then
         value="-"
       fi
       csv_data="${csv_data},`echo "${value}" | $SED -z "s/\n//g" \
       | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
       | $SED "s/:/{%%%}/g" \
       | $SED "s/\&/{%%%%}/g" \
       | $SED "s/\//{%%%%%}/g" \
       | $SED "s/,/{%%%%%%}/g" \
       | $SED "s/_/{%%%%%%%}/g" \
       | $SED "s/(/{%%%%%%%%}/g" \
       | $SED "s/)/{%%%%%%%%%}/g" \
       | $SED "s/\[/{%%%%%%%%%%}/g" \
       | $SED "s/\]/{%%%%%%%%%%%}/g" \
       | $SED "s/|/{%%%%%%%%%%%%}/g" \
       | $SED "s/#/{%%%%%%%%%%%%%}/g" \
       | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" \
       | $SED "s/*/{%%%%%%%%%%%%%%%}/g" \
       | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
       | $SED -r "s/<(.*)>/ #htmltag# /g" \
       | $SED "s/a{%%%%%%%%%%%%%%%%}{%%%%%%%%%%%%%%%%} /<a /g" \
       | $SED "s/{%%%%%%%%%%%%%%%%}{%%%%%%%%%%%%%%%%}a/<{%%%%%}a>/g" `"
     else
       csv_data="${csv_data},-"
     fi
   else
     csv_data="`cat ${ROOT}/databox/${databox}/data/${id}/${key} | $SED -z "s/\n//g" \
     | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
     | $SED "s/:/{%%%}/g" \
     | $SED "s/\&/{%%%%}/g" \
     | $SED "s/\//{%%%%%}/g" \
     | $SED "s/,/{%%%%%%}/g" \
     | $SED "s/_/{%%%%%%%}/g" \
     | $SED "s/(/{%%%%%%%%}/g" \
     | $SED "s/)/{%%%%%%%%%}/g" \
     | $SED "s/\[/{%%%%%%%%%%}/g" \
     | $SED "s/\]/{%%%%%%%%%%%}/g" \
     | $SED "s/|/{%%%%%%%%%%%%}/g" \
     | $SED "s/#/{%%%%%%%%%%%%%}/g" \
     | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" \
     | $SED "s/*/{%%%%%%%%%%%%%%%}/g" \
     | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
     | $SED -r "s/<(.*)>/ #htmltag# /g" \
     | $SED "s/a{%%%%%%%%%%%%%%%%}{%%%%%%%%%%%%%%%%} /<a /g" \
     | $SED "s/{%%%%%%%%%%%%%%%%}{%%%%%%%%%%%%%%%%}a/<{%%%%%}a>/g" `"
   fi
 done
fi

if [ "$flag" = "del" ];then
  csv_data="${primary_key_value}.detouched" 
fi

# update index
if [ ! "$flag" = "del" ];then
  echo "::::::${id}::::::${csv_data}" > $ROOT/databox/$databox/.index.$session
fi

grep -v ::::::${id}:::::: $ROOT/databox/$databox/index >> $ROOT/databox/$databox/.index.$session
if [ -s $ROOT/databox/$databox/.index.$session ];then
  cat $ROOT/databox/$databox/.index.$session > $ROOT/databox/$databox/index
else
  data_check=`ls $ROOT/databox/$databox/data`
  if [ ! "$data_check" ];then
    cat $ROOT/databox/$databox/.index.$session > $ROOT/databox/$databox/index
  fi
fi
rm $ROOT/databox/$databox/.index.$session


exit 0
