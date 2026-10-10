#!/bin/bash

# load env
. %%www/def/.env

# delete zombie session
${small_shell_path}/util/scripts/del_session.sh

# delete util logs
hour=$(date +%-H)
if [ "$hour" = 1 ];then
  ${small_shell_path}/util/scripts/del_log.sh
  ${small_shell_path}/util/scripts/rotate_srvlog.sh
fi

exit 0
