#!/bin/bash

# load small-shell conf
. %%www/def/.small_shell_conf

while true
do
  sudo -u small-shell ${small_shell_path}/util/scripts/del_session.sh
  sudo -u small-shell ${small_shell_path}/util/scripts/del_log.sh
  sudo -u small-shell ${small_shell_path}/util/scripts/rotate_srvlog.sh

  # sleep 1 hour
  sleep 3600
done
