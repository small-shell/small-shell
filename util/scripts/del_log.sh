#!/bin/bash

# .env load
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env

ecron_job=${ROOT}/util/e-cron/log/job
ecron_message=${ROOT}/util/e-cron/log/message
ecron_fileExchange=${ROOT}/util/e-cron/log/fileExchange
audit=${ROOT}/users/audit

find ${ecron_job}/ -type f -mtime +90 | xargs rm -f
find ${ecron_message}/ -type f -mtime +90 | xargs rm -f
find ${ecron_fileExchange}/ -type f -mtime +90 | xargs rm -f
find ${audit}/ -type f -mtime +90 | xargs rm -f

exit 0
