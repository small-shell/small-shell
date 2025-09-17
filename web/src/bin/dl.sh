#!/bin/bash

# load small-shell conf
. %%www/def/.small_shell_conf

# load query string param
for param in $(echo $@)
do

  if [[ $param == databox:* ]]; then
    databox=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == session:* ]]; then
    session=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == pin:* ]]; then
    pin=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

  if [[ $param == id:* ]]; then
    id=$(echo "$param" | $AWK -F":" '{print $2}')
  fi

done

if [ ! "$id" -a ! "$databox" -a ! "$pin" -a "$session" ];then
  echo "Content-Type: text/html"
  echo "error: parameter is not enough for donwloading data"
  exit 1
fi

# SET BASE_COMMAND
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

# load filename
key=$($META get.key:${databox}{file})
filename=$($DATA_SHELL databox:$databox action:get key:$key id:$id format:none | $SED "s/${key}://g" | $AWK -F " #" '{print $1}')

# -----------------
# render contents
# -----------------

echo "Content-Disposition: attachment; filename=\"$filename\""
echo "Content-Type: application/octet-stream"
echo ""
${small_shell_path}/bin/dl session:$session pin:$pin databox:$databox id:$id

if [ "$session" ];then
  rm -rf %%www/tmp/${session}_log
fi

exit 0
