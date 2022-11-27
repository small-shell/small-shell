#!/bin/bash

# load small-shell conf
. %%www/descriptor/.small_shell_conf

while true
do
  sudo -u small-shell ${small_shell_path}/util/scripts/del_session.sh
  sudo -u small-shell ${small_shell_path}/util/scripts/del_log.sh
  sudo -u small-shell ${small_shell_path}/util/scripts/rotate_srvlog.sh

  # sleep 1 day
  sleep 86400
done
