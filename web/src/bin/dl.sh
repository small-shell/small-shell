#!/bin/bash

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == id:* ]]; then
    id=`echo $param | awk -F":" '{print $2}'`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

if [ ! "$id" -a ! "$databox" -a ! "$pin" -a "$session" ];then
  echo "Content-Type: text/html"
  echo "error: parameter is not enough for donwloading data"
  exit 1
fi

# -----------------
# render contents
# -----------------

echo "Content-Disposition: attachment; filename=$filename"
echo "Content-Type: application/octet-stream"
echo ""
sudo -u small-shell ${small_shell_path}/bin/dl session:$session pin:$pin databox:$databox id:$id

if [ "$session" ];then
  rm -rf ../tmp/${session}_log
fi

exit 0
