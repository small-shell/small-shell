#!/bin/bash

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

graph_dir=${ROOT}/util/statistics/graph
rawdata_dir=${ROOT}/util/statistics/rawdata

find ${graph_dir}/ -type f -mtime +365 | grep _h_ | xargs rm -f
find ${rawdata_dir}/ -type f -mtime +365 | grep _h_ | xargs rm -f

exit 0
