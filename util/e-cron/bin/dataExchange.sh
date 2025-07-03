#!/bin/bash

job=$1

# global conf load
SCRIPT_DIR=`dirname $0`
 . ${SCRIPT_DIR}/../../../global.conf

# user check
WHOAMI=`whoami`
if [ ! "$WHOAMI" = "small-shell" ];then
  echo "error: user must be small-shell"
  exit 1
fi

# define parameter
job_log=${ROOT}/util/e-cron/log/job/${job}_log_`date +%Y%m%d`
command_dump=${ROOT}/util/e-cron/log/job/${job}_command_dump_`date +%Y%m%d`
status_que=${ROOT}/util/e-cron/que/status/${job}
tmp_que=${ROOT}/util/e-cron/que/tmp/${job}
file_que=${ROOT}/util/e-cron/que/file

# resource lock
exec 10>${tmp_que}
$FLOCK -n 10
if [ $? -ne 0 ]; then
  echo "`date +%Y-%m-%d` `date +%T` job is already running" >> ${job_log}
  exit 1
fi

# overwrite commmand dump PATH
random=$RANDOM
while [ -f $command_dump.$random ]
do
 sleep 0.01
 count=`expr $count + 1`
 if [ $count -eq 100 ];then
   echo "error: something is wrong"
   exit 1
 fi
 random=$RANDOM
done
command_dump=$command_dump.$random

# job def load
grep -v SCHEDULE  $ROOT/util/e-cron/def/${job}.def > $ROOT/util/e-cron/que/tmp/.${job}_tmp
chmod 766 $ROOT/util/e-cron/que/tmp/.${job}_tmp
. $ROOT/util/e-cron/que/tmp/.${job}_tmp
rm $ROOT/util/e-cron/que/tmp/.${job}_tmp

# get file
count=0
sleep_time=10
if [ "${get_file}" ];then
  if [ ! "$hub_api" ];then
     echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR API_HUB_is_not_defined" > ${status_que}
     echo "`date +%Y-%m-%d` `date +%T` ERROR API HUB is not defined" >> ${job_log}
     if [ -f $tmp_que ];then
       rm -rf $tmp_que
     fi
     exit 1
  else
    if [ ! -d ${file_que}/.${job} ];then
       mkdir ${file_que}/.${job}
    fi
    files=`$CURL -X GET "${hub_api}?req=ls&filename=${get_file}" -H "X-small-shell-authkey:$api_authkey"`

    if [ ! "$files" ];then
      ERROR_FLAG="file check failed"
      echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR target_file_was_not_exist" > ${status_que}
      echo "`date +%Y-%m-%d` `date +%T` ERROR target file was not exist" >> ${job_log}
      if [ -f $tmp_que ];then
        rm -rf $tmp_que
      fi
      exit 1
    fi   

    if [ "$files" = "error: your IP is not allowed to access" ];then
      ERROR_FLAG="Access denied"
      echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR blocked by whitelist" > ${status_que}
      echo "`date +%Y-%m-%d` `date +%T` ERROR bloked by whitelist" >> ${job_log}
      if [ -f $tmp_que ];then
        rm -rf $tmp_que
      fi
      exit 1
    fi

    for file in $files
    do 
      echo "`date +%Y-%m-%d` `date +%T` $CURL -OLJ \"${hub_api}?req=get&filename=${file}\" \
       -H \"X-small-shell-authkey:$api_authkey\"" >> ${command_dump} 2>&1
      (cd ${file_que}/.${job} && $CURL -OLJ "${hub_api}?req=get&filename=${file}"\
       -H "X-small-shell-authkey:$api_authkey" >> ${command_dump} 2>&1) 
    done
  fi

  cp ${file_que}/.${job}/${get_file} ${local_dir}/
  echo "`date +%Y-%m-%d` `date +%T` file ${get_file} downloaded to ${local_dir}" >> ${job_log}
  echo "`date +%Y-%m-%d` `date +%T` ${job} INFO ${get_file}_loaded" > ${status_que}
  rm -rf ${file_que}/.${job}

fi

if [ "${push_file}" ];then
  if [ ! "$hub_api" ];then
    echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR API_HUB_is_not_defined" > ${status_que}
    echo "`date +%Y-%m-%d` `date +%T` ERROR API HUB is not defined" >> ${job_log}
    if [ -f $tmp_que ];then
      rm -rf $tmp_que
    fi
    exit 1
  else
    files=`ls $local_dir/$push_file 2>/dev/null | xargs basename -a  2>/dev/null`
    if [ ! "$files" ];then
      echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR TARGET_FILE_is_not_loaded_on_$local_dir" > ${status_que}
    else
      for file in $files
      do
        echo "`date +%Y-%m-%d` `date +%T` $CURL -X POST \"${hub_api}?req=push&filename=${file}\" -H \"Content-Type:application/octet-stream\" \
        -H \"X-small-shell-authkey:${api_authkey}\" \
        --data-binary @${local_dir}/${file}" >> ${command_dump} 2>&1

        $CURL -X POST "${hub_api}?req=push&filename=${file}" -H "Content-Type:application/octet-stream" \
        -H "X-small-shell-authkey:${api_authkey}" \
        --data-binary @${local_dir}/${file} >> ${command_dump} 2>&1
        result=$?
        error_chk=`grep -e error -e FAILED ${command_dump}`

        if [ "$result" -eq 0 -a ! "$error_chk" ];then
          echo "`date +%Y-%m-%d` `date +%T` file ${file} uploaded to Data exchange API HUB" >> ${job_log}
          echo "`date +%Y-%m-%d` `date +%T` ${job} INFO ${file}_uploaded" > ${status_que}
        else
          echo "`date +%Y-%m-%d` `date +%T` ERROR failed to upload file ${file}" >> ${job_log}
          echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR ${file}_failed_to_upload_to_HUB" > ${status_que}
          if [ -f $tmp_que ];then
             rm -rf $tmp_que
          fi
	  exit 1
        fi
      done
    fi
  fi
fi

if [ -f $tmp_que ];then
  rm -rf $tmp_que
fi

exit 0
