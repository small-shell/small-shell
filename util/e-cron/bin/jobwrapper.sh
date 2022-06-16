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
command_dump_tmp=${ROOT}/util/e-cron/log/job/.${job}_command_dump_tmp
status_que=${ROOT}/util/e-cron/que/status/${job}
tmp_que=${ROOT}/util/e-cron/que/tmp/${job}

# resource lock
exec 9>${tmp_que}
flock -n 9
if [ $? -ne 0 ]; then
  echo "`date +%Y-%m-%d` `date +%T` job is already running" >> ${job_log}
  exit 1
fi

# job def load
grep -v SCHEDULE  $ROOT/util/e-cron/def/${job}.def > $ROOT/util/e-cron/que/tmp/.${job}_tmp
chmod 766 $ROOT/util/e-cron/que/tmp/.${job}_tmp
. $ROOT/util/e-cron/que/tmp/.${job}_tmp

# retry count for message waiting
retry=100

# mesage check
count=0
sleep_time=10
if [ "${input_message}" ];then
  if [ "$hubapi" ];then
    message_chk=`curl -X GET "${hubapi}?req=get&message=${input_message}" -H "X-small-shell-authkey:$api_authkey"`

    if [ "$message_chk" = "" -o "$message_chk" = "KEY AUTHENTICATION FAILED" ];then
      echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR failed_to_connect_to_API_HUB" > ${status_que}
      echo "`date +%Y-%m-%d` `date +%T` ERROR failed to connect to API HUB" >> ${job_log}

      if [ -f $tmp_que ];then
        rm -rf $tmp_que
      fi

      exit 1
    fi

  else
    ls $ROOT/util/e-cron/que/message/${input_message} >/dev/null 2>&1 
    if [ $? -eq 0 ];then
      message_chk="yes"
      rm -rf $ROOT/util/e-cron/que/message/${input_message}
      echo "`date +%Y-%m-%d` `date +%T` localhost grabed ${input_message}" >> $ROOT/util/e-cron/log/messagingHUB.log
    fi
  fi

  while [ "$message_chk" = "message is not ready" ]; do
    sleep 10
    sleep_time=`expr ${count} \* 10`
    echo "`date +%Y-%m-%d` `date +%T` ${job} INFO input_message_${input_message}_was_not_set" > ${status_que}

    if [ ${count} -eq ${retry} ];then
      ERROR_FLAG=message_check_failed
      echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR input_message_${input_message}_was_not_set_by_${sleep_time}_sec" > ${status_que}
      echo "`date +%Y-%m-%d` `date +%T` ERROR input message was not set by ${sleep_time}" >> ${job_log}

      if [ -f $tmp_que ];then
        rm -rf $tmp_que
      fi

      exit 1
    fi
    if [ "$hubapi" ];then
      message_chk=`curl -X GET "${hubapi}?req=get&message=${input_message}" -H "X-small-shell-authkey:$api_authkey"`

      if [ "$message_chk" = "" -o "$message_chk" = "KEY AUTHENTICATION FAILED" ];then
        echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR failed_to_connect_to_API_HUB" > ${status_que}
        echo "`date +%Y-%m-%d` `date +%T` ERROR failed to connect to API HUB" >> ${job_log}

        if [ -f $tmp_que ];then
          rm -rf $tmp_que
        fi

        exit 1
      fi
    else
      ls $ROOT/util/e-cron/que/message/${input_message} >/dev/null 2>&1
      if [ $? -eq 0 ];then
        message_chk="yes"
        rm -rf $ROOT/util/e-cron/que/message/${input_message}
        echo "`date +%Y-%m-%d` `date +%T` localhost grabed ${input_message}" >> $ROOT/util/e-cron/log/messagingHUB.log
      fi
    fi
    ((count += 1))
  done
  echo "`date +%Y-%m-%d` `date +%T` input message ${input_message} confirmed" >> ${job_log}
  echo "`date +%Y-%m-%d` `date +%T` ${job} INFO input_message_${input_message}_confirmed" > ${status_que}
fi


#--------------------
# exec  command
#--------------------
echo "`date +%Y-%m-%d` `date +%T` ${job} started(running) " > ${status_que}

if [ "$que" ];then

  # load general queing
  ls $ROOT/util/e-cron/que/common/${que}.qid* >/dev/null 2>&1
  if [ $? -eq 0 ];then

    for que_file in `ls $ROOT/util/e-cron/que/common/${que}.qid* | xargs basename -a`
    do
      # load que
      . $ROOT/util/e-cron/que/common/$que_file

      if [ $? -eq 0 ];then
        echo "`date +%Y-%m-%d` `date +%T` $que_file loaded" >> ${job_log}
        rm -rf $ROOT/util/e-cron/que/common/$que_file

        # reload exec_command
        . $ROOT/util/e-cron/que/tmp/.${job}_tmp

        # exec command with qued param
        echo "`date +%Y-%m-%d` `date +%T` EXEC ${exec_command} " >> ${job_log}
        echo "`date +%Y-%m-%d` `date +%T` ${exec_command} executed"   >> ${command_dump}
        eval ${exec_command} > ${command_dump_tmp} 2>&1
        result_status=$?
        permission_chk=`grep "Permission denied" ${command_dump_tmp}`
        cat ${command_dump_tmp} >> ${command_dump}
        if [ "$permission_chk" -o ! "$result_status" -eq 0 ];then
          err_flag="err"
        fi
      else
        echo "`date +%Y-%m-%d` `date +%T` failed to load que:$que" >> ${job_log}
      fi

    done

  else
    echo "`date +%Y-%m-%d` `date +%T` que:$que is not in common que" >> ${job_log}
    echo "`date +%Y-%m-%d` `date +%T` ${job} INFO que:$que is not in common que" > ${status_que}
    err_flg="info"
  fi

else
# else means not use general queing

  # exec command without any general que parameter 
  echo "`date +%Y-%m-%d` `date +%T` EXEC ${exec_command} " >> ${job_log}
  echo "`date +%Y-%m-%d` `date +%T` ${exec_command} executed"   >> ${command_dump}
  eval ${exec_command} > ${command_dump_tmp} 2>&1
  result_status=$?
  permission_chk=`grep "Permission denied" ${command_dump_tmp}`
  cat ${command_dump_tmp} >> ${command_dump}
  if [ "$permission_chk" -o ! "$result_status" -eq 0 ];then
    err_flg="err"
  fi

fi


if [ "$err_flg" = "err" ];then

  ERROR_FLAG="execution command failed"
  echo "`date +%Y-%m-%d` `date +%T` ERROR ${ERROR_FLAG} " >> ${job_log}
  echo "`date +%Y-%m-%d` `date +%T` ${job} ERROR ${ERROR_FLAG}" > ${status_que}

  if [ -f $tmp_que ];then
    rm -rf $tmp_que
  fi
  exit 1

elif [ ! "$err_flg" ];then

  echo "`date +%Y-%m-%d` `date +%T` successfully completed"   >> ${job_log}
  echo "`date +%Y-%m-%d` `date +%T` ${job} successfully completed" > ${status_que}

  # create output message
  if [ "${output_message}" ];then
    if [ "$hubapi" ];then
      curl -X POST "${hubapi}?req=push&message=${output_message}" -H "X-small-shell-authkey:$api_authkey" 
    else
      echo "$output_message" > $ROOT/util/e-cron/que/message/$output_message
      echo "`date +%Y-%m-%d` `date +%T` localhost push ${output_message}" >> $ROOT/util/e-cron/log/messagingHUB.log
    fi
    echo "`date +%Y-%m-%d` `date +%T` ${output_message} pushed" >> ${job_log}
    echo "`date +%Y-%m-%d` `date +%T` ${job} INFO ouput_message_${output_message}_pushed" >> ${status_que}
  fi

fi

if [ -f $tmp_que ];then
  rm -rf $tmp_que
fi

exit 0
