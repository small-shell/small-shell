#!/bin/bash

# load env
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env
. ${ROOT}/web/base

count=8
tdir=${www}/log

while [ $count -ge 0 ]
do
  org=${tdir}/srvdump.log.${count}
  new=${tdir}/srvdump.log.$(($count + 1))
  if [ $count -eq 8 -a -f ${org} ];then 
    rm ${org}
  elif [ -f ${org} ];then
    mv ${org} ${new}
  elif [ $count -eq 0 ];then
    cp ${tdir}/srvdump.log ${tdir}/srvdump.log.1
    echo "$(date "+%Y-%m-%d %H:%M:%S") log rotated" > ${tdir}/srvdump.log
  fi
  ((count -= 1))
done

exit 0
