#!/bin/bash

# preprocedure
session_update="required"
auth="%%auth"

# load small-shell conf
. %%www/descriptor/.small_shell_conf

IP_whitelisting=%%IP_whitelisting

# load remote addr
remote_addr=`echo $REMOTE_ADDR | $SED "s/:/-/g"`

# IP restriction check
if [ "$IP_whitelisting" = "yes" ];then
  whitelist_chk=`${small_shell_path}/bin/meta get.IP | grep -v "NO IP RESTRICTION"`
  if [ "$whitelist_chk" ];then
    for IP in $whitelist_chk
    do
      IP=`echo $IP | $SED "s/*//g"`
      if [[ ${remote_addr} == ${IP}* ]];then
        IP_chk=yes
        break
      fi
    done
   
    if [ ! "$IP_chk" = "yes" ];then
      echo "error: your IP is not allowed to access"
      exit 1
    fi
  fi
fi

param=`date +%s`
param="$param:$RANDOM"
count=1
while [ -f %%www/tmp/${param} ]
do
 sleep 0.01
 count=`expr $count + 1`
 if [ $count -eq 100 ];then
   echo "error: please contact to adimin"
   exit 1
 fi
done

# parse QUERY_STRING
echo $QUERY_STRING | $PHP -r "echo urldecode(file_get_contents('php://stdin'));" | tr -d \$ | tr -d \` | $SED "s/\&/\n/g" > %%www/tmp/${param}
cat %%www/tmp/${param} | $SED -e "s/=/=\"/1" | $SED "s/$/\"/g" | $SED "s/^\"//g" > %%www/tmp/${param}.load
chmod 755 %%www/tmp/${param}.load

# load query string
.  %%www/tmp/${param}.load
rm  %%www/tmp/${param}*

if [ ! "$req" ];then
  req=main
fi

if [ "$subapp" ];then
  if [ ! "$req" = "main" -a ! "$req" = "logout" ];then
    req="${subapp}.$req"
  fi
fi

# define contents type except statistics file or graph
if [[ ! "$req" == *stats && ! "$req" == *file ]];then
  echo "Content-Type: text/html"
  echo ""
fi


if [ "$auth" = "required" ];then
  # session verification
  if [[ "$req" == *log_viewer || "$req" == *csv || "$req" == *hash || "$req" == *stats || "$req" == *file ]];then
    session_update=no

    # session check
    session_chk=`sudo -u small-shell ${small_shell_path}/bin/extension_auth app:%%app session_chk:${session} pin:${pin} remote_addr:${remote_addr}`
    session_ip=`echo $session_chk | $AWK -F ":" '{print $2}'`

    if [ ! "${session_ip}" = ${remote_addr} ];then
      if [[ ! "$req" == *stats && ! "$req" == *file ]];then
        echo "Content-Type: text/html"
        echo ""
      fi

      if [ "$req" = "log_viewer" ];then
        echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=$req&id=$id&message=!%20Session%20Expired\">"
        exit 1
      else
        echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=$req&message=!%20Session%20Expired\">"
        exit 1
      fi
    fi
  fi

  if [ "$req" = "logout" ]; then
    sudo -u small-shell ${small_shell_path}/bin/extension_auth app:%%app pin:${pin} remote_addr:${remote_addr} logout:${session}
    echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=main\">"
    exit 0
  fi

  # session update
  if [ "$session_update" = "required" ];then
    get_session=`sudo -u small-shell ${small_shell_path}/bin/extension_auth session_persist:${session} \
    pin:${pin} remote_addr:${remote_addr} app:%%app`

    user_name=`echo $get_session | $AWK -F "," '{print $1}' | $AWK -F ":" '{print $2}'`
    session=`echo $get_session | $AWK -F "," '{print $2}' | $AWK -F ":" '{print $2}'`
    pin=`echo $get_session | $AWK -F "," '{print $3}' | $AWK -F ":" '{print $2}'`

    if [ ! "$user_name" -o ! "$session" -o ! "${pin}" ];then
      if [[ $req == *table ]];then
        echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=$req&message=!%20Session%20Expired\">"
        exit 1
      elif [[ $req == *get ]];then
        echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=$req&id=$id&message=!%20Session%20Expired\">"
        exit 1
      else
        req=main
        echo "<meta http-equiv=\"refresh\" content=\"0; url=./auth.%%app?req=$req&message=!%20Session%20Expired\">"
        exit 1
      fi
    fi
  fi
fi

# dump POST data
if [ "`echo $REQUEST_METHOD | grep -i "POST"`" ];then

  if [ "`echo $CONTENT_TYPE | grep "application/json"`" ];then
    method=json
  elif [ "`echo $CONTENT_TYPE | grep "multipart/form-data"`" ];then
    method=multipart
  elif [ "`echo $CONTENT_TYPE | grep "application/octet-stream"`" ];then
    method=data-binary
  else
    method=urlenc
  fi

  mkdir %%www/tmp/$session
  # dump posted data
  dd bs=${CONTENT_LENGTH} of=%%www/tmp/$session/input 2>/dev/null
  %%www/bin/parse.sh $session $method

fi

#----------------------------
# routing to action scripts
#----------------------------

case "$req" in
  
  "main")
    %%www/bin/%%app_main.sh session:$session pin:$pin user_name:$user_name remote_addr:${remote_addr};;

  "get")
    %%www/bin/%%app_get.sh session:$session pin:$pin user_name:$user_name id:$id duplicate:$duplicate;;

  "set")
    %%www/bin/%%app_set.sh session:$session pin:$pin user_name:$user_name id:$id;;

  "del")
    %%www/bin/%%app_del.sh databox:$databox session:$session pin:$pin id:$id ;;

  "table")
    table_command="`echo $table_command | $SED "s/ /{%%space}/g"`"
    %%www/bin/%%app_table.sh session:$session pin:$pin user_name:$user_name id:$id page:$page table_command:$table_command line:$line;;

  "log_viewer")
    %%www/bin/%%app_log_viewer.sh session:$session pin:$pin user_name:$user_name id:$id ;;

  "file")
    %%www/bin/%%app_dl.sh session:$session pin:$pin user_name:$user_name id:$id ;;

  *)
    echo "error: wrong request";;

esac

exit 0
