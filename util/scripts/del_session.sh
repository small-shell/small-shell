#!/bin/bash

# load env
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env

session_dir=${ROOT}/tmp/session
que_session_dir=${ROOT}/tmp/que

find ${session_dir}/ -type l -cmin +240 | xargs rm -f 
find ${session_dir}/ -type f -cmin +240 | xargs rm -f 
find ${que_session_dir}/ -type f -cmin +240 | xargs rm -f 

exit 0
