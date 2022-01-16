#!/bin/bash

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

session_dir=${ROOT}/tmp/session
que_session_dir=${ROOT}/tmp/que

find ${session_dir}/ -type f -amin +240 | xargs rm -f 
find ${session_dir}/ -type l -amin +240 | xargs rm -f 
find ${que_session_dir}/ -type f -amin +240 | xargs rm -f 

exit 0
