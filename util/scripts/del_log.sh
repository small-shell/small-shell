#!/bin/bash

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

log_dir=${ROOT}/util/e-cron/log/joblog

find ${log_dir}/ -type f -mtime +180 | xargs rm -f

exit 0
