#!/bin/bash

#---------------------------------------------------------
# usage: del_job.sh $job
#---------------------------------------------------------

job=$1

WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# global conf load
SCRIPT_DIR=$(dirname $0)
 . ${SCRIPT_DIR}/../../global.conf

# error handling
if [ ! "$job" ];then
  echo "error: job name is null" 
  exit 1
fi

if [ ! -f ${ROOT}/util/e-cron/def/${job}.def ];then
  echo "error: there is no job{${job}}"
  exit 1
fi

chk_job=$(sudo -u small-shell ${ROOT}/bin/e-cron ls | grep ^${job}.enabled)
if [ "$chk_job" ];then
  echo "error: ${job} is enabled job, please disable job first by executing \"sudo -u small-shell ${ROOT}/bin/e-cron disable.${job}\""
  exit 1
fi

# delete job
rm -f ${ROOT}/util/e-cron/def/${job}.def
rm -f ${ROOT}/util/e-cron/def/.${job}.dump

echo "job{${job}} has been deleted"

exit 0
