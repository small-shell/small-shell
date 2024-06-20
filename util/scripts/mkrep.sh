#!/bin/bash

#-----------------------------------
# PARAMS for mkrep.sh
#------------------------------------
# show.pub	#show public key
# reg.replica	#regist new server as replica server on master server
# reg.master	#regist master server on replica server
# purge		#purge all replication setting
#------------------------------------

# load param
param=$1
small_shell_home=/home/small-shell

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# load base 
if [ ! -f $ROOT/web/base ];then
  echo "error: please generate Base APP first"
  exit 1
else
  . $ROOT/web/base
fi


if [ ! "$index_url" ];then
  echo "error: replication option can not be enabled for this server type, it's only for small-shell default WEB server"
  exit 1
fi

# gen tmpdir
random=$RANDOM
while [ -d $ROOT/tmp/gen/$random ]
do
 sleep 0.01
 count=`expr $count + 1`
 if [ $count -eq 100 ];then
   echo "error: something is wrong"
   exit 1
 fi
 random=$RANDOM
done
mkdir $ROOT/util/scripts/tmp/$random
tmp_dir="$ROOT/util/scripts/tmp/$random"

# handle kill signal
trap 'clear_dialog' SIGINT
function clear_dialog(){

  if [ "$tmp_flg" = "yes" ];then
    if [ -f /home/small-shell/.ssh/authorized_keys ];then
      if [ -f /home/small-shell/.ssh/authorized_keys.org ];then
        cat /home/small-shell/.ssh/authorized_keys.org > /home/small-shell/.ssh/authorized_keys
      else
        rm /home/small-shell/.ssh/authorized_keys
      fi
    fi
  fi

  if [ -d "$tmp_dir" ];then
    echo ""
    echo "tmp file will be deleted, please try again from beginning"
    rm -rf $tmp_dir
    exit 1
  else
    echo ""
    echo "dialog will be ended, please try again from beginning"
    exit 1
  fi
}

# initialize key
function initialize_key(){
  if [ ! -d ${small_shell_home} ];then
    mkdir ${small_shell_home}
    chown small-shell:small-shell ${small_shell_home}
  fi
  usermod -s /bin/bash small-shell
  sudo -u small-shell ssh-keygen -N "" -t rsa
}


# HANDLE REQUEST
if [ "$param" = "show.pub" ];then
  if [ ! -f ${small_shell_home}/.ssh/id_rsa.pub ];then
    initialize_key
  fi
  clear
  echo "This server's public key"
  echo "-------------------------------------------------------------------------------------------------------------"
  cat ${small_shell_home}/.ssh/id_rsa.pub
  echo "-------------------------------------------------------------------------------------------------------------"
fi

if [ "$param" = "reg.replica" ];then

  # check lsyncd 
  which lsyncd  > /dev/null 2>&1
  if [ ! $? -eq 0 ];then
    echo "erorr: you need to install lsyncd"
    rm -rf $tmp_dir
    exit 1
  fi

  which rsync  > /dev/null 2>&1
  if [ ! $? -eq 0 ];then
    echo "erorr: you need to install rsync"
    rm -rf $tmp_dir
    exit 1
  fi

  # generate public key
  if [ ! -f /home/small-shell/.ssh/id_rsa.pub ];then
    initialize_key
  fi

  # load base setting
  . $ROOT/web/base

  # read replica IP or FQDN
  echo -n "Replica server IP or FQDN: "
  read replica

  if [ "$replica_hosts" ];then
    chk_host=`echo "$replica_hosts" | $SED "s/ /\n/g" | grep ^${replica}$`
  fi

  if [ ! "$chk_host" ];then

    if [ ! "$cluster_base_url" ];then
      cluster_flag=new
      echo -n "Load balancing IP or FQDN: "
      read cluster_IP
      cluster_base_url=`echo $base_url | $SED "s/$server/$cluster_IP/g"`
      cluster_index_url=`echo $index_url | $SED "s/$server/$cluster_IP/g"`
      get_test=`$CURL -k ${cluster_base_url}shelltest.cgi | grep OK`
      if [ ! "$get_test" ];then
        echo "error: failed to connect ${cluster_base_url}shelltest.cgi,"
        echo "you need to review your DNS setting or Load balancer or Firewall setting."
        rm -rf $tmp_dir
        exit 1 
      else
        echo "connection test to ${cluster_base_url}shelltest.cgi success"
        sleep 1
      fi
    fi

    # read replica.pub
    clear
    echo "------------------------please paste public key of replica server to next line------------------------"
    read replica_pub

    # update authorizedkeys
    tmp_flg=yes
    if [ -f /home/small-shell/.ssh/authorized_keys ];then
      cp /home/small-shell/.ssh/authorized_keys /home/small-shell/.ssh/authorized_keys.org
    fi
    echo "$replica_pub" | grep -v "small-shell public key is here" | grep -v "this is public key to be copied" \
    | grep -v "\-\-\-\-\-\-\-\-\-\-"  >> /home/small-shell/.ssh/authorized_keys
    chown small-shell:small-shell /home/small-shell/.ssh/authorized_keys
    chmod 600 /home/small-shell/.ssh/authorized_keys

    # connection test
    sleep 2
    clear
    echo "trying to connect ${replica}"
    ls_chk=`sudo -u small-shell ssh -oStrictHostKeyChecking=no $replica ls $ROOT/global.conf`
    if [ ! "$ls_chk" = "$ROOT/global.conf" ];then
      echo "--------------------------------------------Action required---------------------------------------------------"
      echo "Master public key seems not copied to $replica yet."
      echo "please put public key by executing \"sudo $ROOT/util/scripts/mkrep.sh reg.master\" on replica server for success of connection test."
      echo "by the way, this script will retry to connect replica every 30 sec. for the interuption, just execute ctrl + c"
      echo "---------------------------------------------------------------------------------------------------------------"
      echo "this is public key to be copied"
      echo "---------------------------------------------------------------------------------------------------------------"
      cat /home/small-shell/.ssh/id_rsa.pub
      echo "---------------------------------------------------------------------------------------------------------------"
      count=0
      while [ ! "$ls_chk" = "$ROOT/global.conf" ]
      do
        sleep 30
        ls_chk=`sudo -u small-shell ssh -oStrictHostKeyChecking=no $replica ls $ROOT/global.conf`
        ((count += 1))
        if [ $count -gt 120 ];then
           echo "warn: retry count has been over threthhold(120 time), script will be gone. please try again."
           rm -rf $tmp_dir

           if [ -f /home/small-shell/.ssh/authorized_keys ];then
             if [ -f /home/small-shell/.ssh/authorized_keys.org ];then
               cat /home/small-shell/.ssh/authorized_keys.org > /home/small-shell/.ssh/authorized_keys
             else
               rm /home/small-shell/.ssh/authorized_keys
             fi
           fi

           exit 1 
        fi
      done
    fi


    # update env files
    if [ "$cluster_flag" = "new" ];then
      echo "cluster_base_url=\"$cluster_base_url\"" >> $ROOT/web/base
      echo "cluster_index_url=\"$cluster_index_url\"" >> $ROOT/web/base
      echo "replica_hosts=\"$replica\"" >> $ROOT/web/base
      echo "cluster_base_url=\"$cluster_base_url\"" >> ${www}/descriptor/.small_shell_conf
      echo "replica=\"registered\"" >> ${www}/descriptor/.small_shell_conf

      # initialiize .rep.def
      cat <<EOF > $ROOT/util/scripts/.rep.def 
ssync = {
        default.rsync,
        delete=yes,
        delay= 1,
        rsync = {
          owner = true,
          group = true,
          rsh = "/usr/bin/ssh -i /home/small-shell/.ssh/id_rsa -o UserKnownHostsFile=/home/small-shell/.ssh/known_hosts",
          _extra = {
           "--exclude=*base"
           }
        }
}

EOF

      # update menu for Base APP
      for target in `ls ${www}/descriptor/common_parts/common* | grep -v .org$ | xargs basename -a`
      do
        cp ${www}/descriptor/common_parts/${target} ${www}/descriptor/common_parts/${target}.org
        cat ${www}/descriptor/common_parts/${target} | $SED "s#./base#${cluster_base_url}base#g" > ${tmp_dir}/${target}
        cat ${tmp_dir}/${target} > $www/descriptor/common_parts/${target}
        echo "updated $target"
      done

      # update table of Base APP
      target=table.html.def
      app=base
      cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org
      cat ${www}/descriptor/${target} | $SED "s#./${app}?#${cluster_base_url}${app}?#g" > ${tmp_dir}/${target}
      cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
      echo "updated $target"

      # update menu for Scratch APP
      . $ROOT/util/scripts/.authkey
      permission=`$ROOT/bin/meta get.attr:sys`
      if [ "$permission" = "ro" ];then
        $ROOT/adm/ops set.attr:sys{rw} > /dev/null 2>&1
      fi

      for target in `ls ${www}/descriptor/common_parts/*_common_menu* | grep -v .org$ | xargs basename -a`
      do
        app=`head -1 ${www}/descriptor/common_parts/${target} | $AWK -F "./" '{print $2}' | $AWK -F "?" '{print $1}'`
        chk_team=`grep "# controller for Scratch APP #team" ${cgidir}/${app}`

        if [ -f ${cgidir}/${app} -a ! -d ${tmp_dir}/${app} -a ! "${chk_team}" ];then       
          # update UI.md.def
          mkdir ${tmp_dir}/${app}

          id=`sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:get command:head_-1 format:none | awk -F "," '{print $1}'`
          sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:righth format:none \
          | $SED "s#./${app}#${cluster_base_url}${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/righth://g"  > ${tmp_dir}/${app}/righth
          sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:righth input_dir:${tmp_dir}/${app}

          sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:lefth format:none \
          | $SED "s#./${app}#${cluster_base_url}${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/lefth://g"  > ${tmp_dir}/${app}/lefth
          sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:lefth input_dir:${tmp_dir}/${app}

        fi

        # update desc/menu
        cp ${www}/descriptor/common_parts/${target} ${www}/descriptor/common_parts/${target}.org
        cat ${www}/descriptor/common_parts/${target}| $SED "s#./${app}#${cluster_base_url}${app}#g" > ${tmp_dir}/${target}
        cat ${tmp_dir}/${target} > ${www}/descriptor/common_parts/${target}
        echo "updated $target"

      done

      if [ "$permission" = "ro" ];then
        $ROOT/adm/ops set.attr:sys{ro} > /dev/null 2>&1
      fi

      # update descriptor for Scratch APP
      for app in `ls ${cgidir} | grep -v base | grep -v api | grep -v e-cron | grep -v css \
      | grep -v ^_ | grep -v shelltest.cgi | grep -v "auth." | xargs basename -a  2>/dev/null`
      do
        type3_chk=`grep "# controller for Scratch APP" ${cgidir}/${app}`
        if [ "$type3_chk" ];then 
          subapps=`cat ${cgidir}/${app} | grep ".get\")" | grep -v "\"get\")" | $SED -z "s/\n/ /g" | $SED "s/\"//g" | $SED "s/.get)//g"`
          for target in `ls ${www}/descriptor/${app}_table.html.def | xargs basename -a`
          do
            cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org
            cat ${www}/descriptor/${target} | $SED "s#./${app}?#${cluster_base_url}${app}?#g" > ${tmp_dir}/${target}
            cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
            echo "updated $target"
          done

          if [ "$subapps" ];then
            for subapp in $subapps
            do
              for target in `ls ${www}/descriptor/${subapp}_table.html.def | xargs basename -a 2>/dev/null`
              do
                cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org
                cat ${www}/descriptor/${target} | $SED "s#./${app}?#${cluster_base_url}${app}?#g" > ${tmp_dir}/${target}
                cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
                echo "updated $target"
              done
            done
          fi
        fi 
      done

      # update index
      for target in `ls ${www}/html | grep -v index | xargs basename -a`
      do
        if [ -f ${www}/html/${target}/index.html ];then
          chk_form=`cat ${cgidir}/${target} | grep "controller for FORM"`
          if [ ! "$chk_form" ];then
            cp ${www}/html/${target}/index.html ${www}/html/${target}/index.html.org
            cat ${www}/html/${target}/index.html | $SED "s#${base_url}#${cluster_base_url}#g" > ${tmp_dir}/${target}.index.html
            cat ${tmp_dir}/${target}.index.html > ${www}/html/${target}/index.html
          fi
        fi
      done

      chown -R small-shell:small-shell ${www}/descriptor
      chown -R small-shell:small-shell ${www}/html

    else
      new_replica_hosts=`echo "$replica_hosts" | $SED "s/\"//g" | $SED "s/$/ $replica/g"`
      echo "replica_hosts=\"$new_replica_hosts\"" >> $ROOT/web/base

    fi

  # update .rep.def
  cat <<EOF >> $ROOT/util/scripts/.rep.def 
sync{
    ssync,
    source="$ROOT/tmp",
    target="small-shell@${replica}:$ROOT/tmp"
}

sync{
    ssync,
    source="$ROOT/users",
    target="small-shell@${replica}:$ROOT/users"
}

sync{
    ssync,
    source="/usr/local/small-shell/databox",
    target="small-shell@${replica}:$ROOT/databox"
}

EOF

  fi

  chk_process=`ps -ef | grep lsyncd | grep -v grep`
  if [ "$chk_process" ];then
    echo "warn: trying to stop lsyncd to install new setting"
    systemctl stop lsyncd
  fi

  cat $ROOT/util/scripts/.rep.def > /etc/lsyncd/lsyncd.conf.lua
  systemctl restart lsyncd
  systemctl status lsyncd
  systemctl enable lsyncd


  echo ""
  echo "---------------------------------------------------------------"
  echo "Replication is successfully started."
  echo "---------------------------------------------------------------"
  echo "Please be aware that Access URL is changed,"
  echo "From ${index_url}\${app} To ${cluster_index_url}\${app}"
  echo ""
fi

if [ "$param" = "reg.master" ];then

  # check rsync 
  which rsync  > /dev/null 2>&1
  if [ ! $? -eq 0 ];then
    echo "erorr: you need to install rsync command"
    rm -rf $tmp_dir
    exit 1
  fi

  # check public key
  if [ ! -f /home/small-shell/.ssh/id_rsa.pub ];then
    initialize_key
  fi

  # load web/base
  . $ROOT/web/base

  # read master IP or FQDN
  echo -n "Master server IP or FQDN: "
  read new_master

  if [ ! "$master" = "$new_master" ];then

    # read replica.pub
    clear
    echo "------------------------ please paste public key of master server to next line ------------------------"
    read master_pub

    # update authorizedkeys
    tmp_flg=yes
    if [ -f /home/small-shell/.ssh/authorized_keys ];then
      cp /home/small-shell/.ssh/authorized_keys /home/small-shell/.ssh/authorized_keys.org
    fi
    echo "$master_pub" | grep -v "small-shell public key is here" | grep -v "this is public key to be copied" \
    | grep -v "\-\-\-\-\-\-\-\-\-\-"  >> /home/small-shell/.ssh/authorized_keys
    chown small-shell:small-shell /home/small-shell/.ssh/authorized_keys
    chmod 600 /home/small-shell/.ssh/authorized_keys

    # connection test
    sleep 2
    clear
    echo "trying to connect $new_master"
    ls_chk=`sudo -u small-shell ssh -oStrictHostKeyChecking=no $new_master ls $ROOT/global.conf`
    if [ ! "$ls_chk" = "/usr/local/small-shell/global.conf" ];then
      echo "--------------------------------------------Action required---------------------------------------------------"
      echo "Replica server key seems not copied to $new_master yet." 
      echo "please execute \"sudo $ROOT/util/scripts/mkrep.sh reg.replica\" on master server for success of connection test."
      echo "by the way, this script will retry to connect master every 30 sec. for the interuption, just execute ctrl + c"
      echo "---------------------------------------------------------------------------------------------------------------"
      echo "this is public key to be copied"
      echo "---------------------------------------------------------------------------------------------------------------"
      cat /home/small-shell/.ssh/id_rsa.pub
      echo "---------------------------------------------------------------------------------------------------------------"
      count=0
      while [ ! "$ls_chk" = "$ROOT/global.conf" ]
      do
        sleep 30
        ls_chk=`sudo -u small-shell ssh -oStrictHostKeyChecking=no $new_master ls $ROOT/global.conf`
        ((count += 1))
        if [ $count -gt 120 ];then
           echo "warn: retry count has been over threthhold(120 time), script will be gone. please try again."
           rm -rf $tmp_dir

           if [ -f /home/small-shell/.ssh/authorized_keys ];then
             if [ -f /home/small-shell/.ssh/authorized_keys.org ];then
               cat /home/small-shell/.ssh/authorized_keys.org > /home/small-shell/.ssh/authorized_keys
             else
               rm /home/small-shell/.ssh/authorized_keys
             fi
           fi

           exit 1
        fi
      done
    fi

    # update env
    cat $ROOT/web/base | grep -v "master=\"" > ${tmp_dir}/base 
    echo "master=\"$new_master\"" >>  ${tmp_dir}/base 
    cat ${tmp_dir}/base > $ROOT/web/base
    master=$new_master
  fi

  # load cluster_base_url
  cluster_base_url=`sudo -u small-shell ssh $master cat $ROOT/web/base | grep cluster_base_url \
  | $SED "s/cluster_base_url=//g" | $SED "s/\"//g"` 

  echo "waiting update of web/base of master server"
  echo "this process will retry to connect master every 10 sec. for the interuption, just execute ctrl + c"
  count=0
  while [ ! "$cluster_base_url" ]
  do
    sleep 10
    cluster_base_url=`sudo -u small-shell ssh $master cat $ROOT/web/base | grep cluster_base_url \
    | $SED "s/cluster_base_url=//g" | $SED "s/\"//g"` 
    ((count += 1))

       if [ $count -gt 120 ];then
           echo "warn: retry count has been over threthhold(120 time), script will be gone. please try again."
           rm -rf $tmp_dir
    
           if [ -f /home/small-shell/.ssh/authorized_keys ];then
             if [ -f /home/small-shell/.ssh/authorized_keys.org ];then
               cat /home/small-shell/.ssh/authorized_keys.org > /home/small-shell/.ssh/authorized_keys
             else
               rm /home/small-shell/.ssh/authorized_keys
             fi
           fi
       fi
  done

  # update env
  cat $ROOT/web/base | grep -v "cluster_base_url=\"" > ${tmp_dir}/base
  echo "cluster_base_url=\"$cluster_base_url\"" >>  ${tmp_dir}/base
  cat ${tmp_dir}/base > $ROOT/web/base


  # remove local APP 
  rm -rf ${www}/html/base
  rm -f ${www}/bin/*.sh
  rm -f ${www}/descriptor/*.html.def
  rm -f ${www}/descriptor/*.css.def
  rm -f ${www}/descriptor/common_parts/*
  rm -f ${www}/cgi-bin/*

  # backup small_shell_conf
  mv ${www}/descriptor/.small_shell_conf ${www}/descriptor/small_shell_conf.org

  # get latest codes from master
  sudo -u small-shell scp -r small-shell@${master}:${www}/descriptor ${www}
  sudo -u small-shell scp -r small-shell@${master}:${www}/html ${www}
  sudo -u small-shell scp -r small-shell@${master}:${cgidir}/* ${cgidir}
  sudo -u small-shell scp -r small-shell@${master}:${www}/bin ${www}
  
  # update descriptor for scratch APP
  master_base_url=`sudo -u small-shell ssh $master cat $ROOT/web/base | grep -v cluster_base_url | grep base_url \
  | $SED "s/base_url=//g" | $SED "s/\"//g"` 

  for app in `ls ${cgidir} | grep -v base | grep -v api | grep -v e-cron | grep -v css \
  | grep -v ^_ | grep -v shelltest.cgi | grep -v "auth." | xargs basename -a  2>/dev/null`
  do
    type3_chk=`grep "# controller for Scratch APP" ${cgidir}/${app}`
    if [ "$type3_chk" ];then
      subapps=`cat ${cgidir}/$app | grep ".get\")" | grep -v "\"get\")" | $SED -z "s/\n/ /g" | $SED "s/\"//g" | $SED "s/.get)//g"`

      for target in `ls ${www}/descriptor/${app}_get* | grep -v .org$ | xargs basename -a`
      do
        cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org  
        cat ${www}/descriptor/${target} | $SED "s#./${app}?%%params&req=set\&id=%%id#${master_base_url}${app}?%%params\&req=set\&id=%%id#g" \
        |$SED "s#./${app}?%%params\&req=del\&id=%%id#${master_base_url}${app}?%%params\&req=del\&id=%%id#g" > ${tmp_dir}/${target}
        cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
        echo "updated $target"
      done
   
      if [ "$subapps" ];then
        for subapp in $subapps
        do
          for target in `ls ${www}/descriptor/${subapp}_get* | grep -v .org$ | xargs basename -a 2>/dev/null`
          do
            cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org
            cat ${www}/descriptor/${target} | $SED "s#./${app}?%%params&req=set\&id=%%id#${master_base_url}${app}?%%params\&req=set\&id=%%id#g" \
            |$SED "s#./${app}?%%params\&req=del\&id=%%id#${master_base_url}${app}?%%params\&req=del\&id=%%id#g" > ${tmp_dir}/${target}
            cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
            echo "updated $target"
          done
        done
      fi
    fi
  done

  # update base APP
  for target in `ls ${www}/descriptor/get_* | grep -v _master_failed | grep -v .org$ | xargs basename -a 2>/dev/null` 
  do
    cp ${www}/descriptor/${target} ${www}/descriptor/${target}.org
    cat ${www}/descriptor/${target} | $SED "s#./base?%%params&req=set\&id=%%id#${master_base_url}base?%%params\&req=set\&id=%%id#g" \
    |$SED "s#./base?%%params\&req=get\&id=%%id#${master_base_url}base?%%params\&req=get\&id=%%id#g" \
    |$SED "s#./base?%%params\&req=del\&id=%%id#${master_base_url}base?%%params\&req=del\&id=%%id#g" > ${tmp_dir}/${target}
    cat ${tmp_dir}/${target} > ${www}/descriptor/${target}
    echo "updated $target"
  done

  cp ${www}/descriptor/import_form.html.def ${www}/descriptor/import_form.html.def.org
  cat ${www}/descriptor/import_form.html.def | $SED "s#action=\"./base#action=\"${master_base_url}base#g" > ${tmp_dir}/import_form.html.def
  cat ${tmp_dir}/import_form.html.def > ${www}/descriptor/import_form.html.def
  echo "updated import_form.html.def"

  # update index
  for target in `ls ${www}/html | grep -v index | xargs basename -a 2>/dev/null`
  do
    if [ -f ${www}/html/${target}/index.html ];then
      chk_form=`cat ${cgidir}/${target} | grep "controller for FORM"`
      if [ ! "$chk_form" ];then
        cp ${www}/html/${target}/index.html ${www}/html/${target}/index.html.org
        cat ${www}/html/${target}/index.html | $SED "s#${base_url}#${cluster_base_url}#g" \
        | $SED "s#${master_base_url}#${cluster_base_url}#g" > ${tmp_dir}/${target}.index.html
        cat ${tmp_dir}/${target}.index.html > ${www}/html/${target}/index.html
      else
        cp ${www}/html/${target}/index.html ${www}/html/${target}/index.html.org
        cat ${www}/html/${target}/index.html | $SED "s#./${server}#${master_base_url}#g" > ${tmp_dir}/${target}.index.html
        cat ${tmp_dir}/${target}.index.html > ${www}/html/${target}/index.html
        mv ${cgidir}/${target} ${cgidir}/_${target}
        cat $ROOT/web/src/cgi-bin/tmplt_redirect_form | $SED "s#%%www#${www}#g" | $SED "s#%%master_base_url#${master_base_url}#g" \
        | $SED "s/%%app/${target}/g" > ${cgidir}/${target} 
        chmod 755 ${cgidir}/${target}
        chown small-shell:small-shell ${cgidir}/${target}
      fi
    fi
  done

  # update desc/.small-shell_conf
  cat ${www}/descriptor/small_shell_conf.org | grep -v master=\" | grep -v replica=\" > ${tmp_dir}/small_shell_conf
  echo "master=\"$master\"" >> ${tmp_dir}/small_shell_conf
  cat ${tmp_dir}/small_shell_conf > ${www}/descriptor/.small_shell_conf
  rm -f ${www}/descriptor/small_shell_conf.org 

  # update api authkey
  api_authkey=`sudo -u small-shell ssh $master cat $ROOT/web/base | grep api_authkey \
  | $SED "s/api_authkey=//g" | $SED "s/\"//g"` 

  
  cat $ROOT/web/base | grep -v api_authkey > ${tmp_dir}/base 
  echo "api_authkey=\"$api_authkey\"" >> ${tmp_dir}/base
  cat ${tmp_dir}/base > $ROOT/web/base


  # update sys authkey
  sys_authkey=`sudo -u small-shell ssh $master cat $ROOT/util/scripts/.authkey \
  | $SED "s/authkey=//g" | $SED "s/\"//g"`
  echo "authkey=\"${sys_authkey}\"" > $ROOT/util/scripts/.authkey


  chown -R small-shell:small-shell ${www}/descriptor
  chown -R small-shell:small-shell ${www}/html

  echo "---------------------------------------------------------------"
  echo "Replication option is successfully enabled."
  echo "---------------------------------------------------------------"

fi

if [ "$param" = "purge" ];then

  # load web/base
  . $ROOT/web/base

  if [ ! "$cluster_base_url" ];then
    echo "error: it seems replication setting is already purged"
    rm -rf ${tmp_dir}
    exit 1
  fi

  if [ "$replica_hosts" ];then
    systemctl stop lsyncd
    systemctl disable lsyncd
 
    # initialize cluster definition
    cat <<EOF > $ROOT/util/scripts/.rep.def
ssync = {
        default.rsync,
        delete=yes,
        delay= 1,
        rsync = {
          owner = true,
          group = true,
          rsh = "/usr/bin/ssh -i /home/small-shell/.ssh/id_rsa -o UserKnownHostsFile=/home/small-shell/.ssh/known_hosts"
        }
}
EOF
    mv /etc/lsyncd/lsyncd.conf.lua /etc/lsyncd/lsyncd.conf.lua.org

    # update web/base desc/.small_shell_conf
    cat $ROOT/web/base | grep -v cluster_index_url | grep -v cluster_base_url | grep -v replica_hosts=\" > ${tmp_dir}/base
    cat ${tmp_dir}/base > ${ROOT}/web/base
    cat ${www}/descriptor/.small_shell_conf | grep -v replica=\"registered\" | grep -v cluster_base_url > ${tmp_dir}/small_shell_conf
    cat ${tmp_dir}/small_shell_conf > ${www}/descriptor/.small_shell_conf


    . $ROOT/util/scripts/.authkey
    permission=`$ROOT/bin/meta get.attr:sys`
    if [ "$permission" = "ro" ];then
      $ROOT/adm/ops set.attr:sys{rw} > /dev/null 2>&1
    fi

    # restore descriptor
    for bkup in `ls ${www}/descriptor/*.org 2>/dev/null | xargs basename -a 2>/dev/null`
    do
       target=`echo $bkup | awk -F ".org" '{print $1}'`
       cat ${www}/descriptor/${bkup} > ${www}/descriptor/${target}
    done

    # restore menu
    for bkup in `ls ${www}/descriptor/common_parts/*.org 2>/dev/null | xargs basename -a 2>/dev/null`
    do

      app=`head -1 ${www}/descriptor/common_parts/${bkup} | $AWK -F "./" '{print $2}' | $AWK -F "?" '{print $1}'`
      chk_team=`grep "# controller for Scratch APP #team" ${cgidir}/${app}`

      if [ -f ${cgidir}/${app} -a ! -d ${tmp_dir}/${app} -a ! ${app} = "base" -a ! "${chk_team}" ];then
        # update UI.md.def
        mkdir ${tmp_dir}/${app}
        id=`sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:get command:head_-1 format:none | awk -F "," '{print $1}'`

        sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:righth format:none \
        | $SED "s#${cluster_base_url}${app}#./${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/righth://g" > ${tmp_dir}/${app}/righth
        sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:righth input_dir:${tmp_dir}/${app}

        sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:lefth format:none \
        | $SED "s#${cluster_base_url}${app}#./${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/lefth://g"  > ${tmp_dir}/${app}/lefth
        sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:lefth input_dir:${tmp_dir}/${app}
      fi

       target=`echo $bkup | awk -F ".org" '{print $1}'`
       cat ${www}/descriptor/common_parts/${bkup} > ${www}/descriptor/common_parts/${target}
    done

    if [ "$permission" = "ro" ];then
      $ROOT/adm/ops set.attr:sys{ro} > /dev/null 2>&1
    fi

    # restore index
    for target in `ls ${www}/html | grep -v index | xargs basename -a 2>/dev/null`
    do
      if [ -f ${www}/html/${target}/index.html ];then
        cat ${www}/html/${target}/index.html | $SED "s#${cluster_base_url}#${base_url}#g" > ${tmp_dir}/${target}.index.html
        cat ${tmp_dir}/${target}.index.html > ${www}/html/${target}/index.html
      fi
    done 

    chown -R small-shell:small-shell ${www}/descriptor
    chown -R small-shell:small-shell ${www}/html

    # purge authorized key
    rm -f /home/small-shell/.ssh/authorized_keys

    echo ""
    echo "---------------------------------------------------------------"
    echo "Replication is successfully purged."
    echo "---------------------------------------------------------------"
    echo "Replication setting has been removed on master, you need to exec \"mkrep.sh purge\" on replica server as well."
    echo ""

  else
     
    # update web/base desc/.small_shell_conf
    cat $ROOT/web/base | grep -v master=\" | grep -v cluster_base_url=\" > ${tmp_dir}/base
    cat ${tmp_dir}/base > ${ROOT}/web/base
    cat ${www}/descriptor/.small_shell_conf | grep -v master= > ${tmp_dir}/small_shell_conf
    cat ${tmp_dir}/small_shell_conf > ${www}/descriptor/.small_shell_conf

    # restore descriptor
    for bkup in `ls ${www}/descriptor/*.org 2>/dev/null | xargs basename -a 2>/dev/null`
    do
       target=`echo $bkup | awk -F ".org" '{print $1}'`
       cat ${www}/descriptor/${bkup} > ${www}/descriptor/${target}
    done

    . $ROOT/util/scripts/.authkey
    permission=`$ROOT/bin/meta get.attr:sys`
    if [ "$permission" = "ro" ];then
      $ROOT/adm/ops set.attr:sys{rw} > /dev/null 2>&1
    fi

    # restore menu
    for bkup in `ls ${www}/descriptor/common_parts/*.org 2>/dev/null | xargs basename -a 2>/dev/null`
    do

      app=`head -1 ${www}/descriptor/common_parts/${bkup} | $AWK -F "./" '{print $2}' | $AWK -F "?" '{print $1}'`
      chk_team=`grep "# controller for Scratch APP #team" ${cgidir}/${app}`

      if [ -f ${cgidir}/${app} -a ! -d ${tmp_dir}/${app} -a ! ${app} = "base" -a ! "${chk_team}" ];then
        # update UI.md.def
        mkdir ${tmp_dir}/${app}
        id=`sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:get command:head_-1 format:none | awk -F "," '{print $1}'`

        sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:righth format:none \
        | $SED "s#${cluster_base_url}${app}#./${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/righth://g" > ${tmp_dir}/${app}/righth
        sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:righth input_dir:${tmp_dir}/${app}

        sudo -u small-shell $ROOT/bin/DATA_shell authkey:$authkey databox:${app}.UI.md.def action:get id:${id} key:lefth format:none \
        | $SED "s#${cluster_base_url}${app}#./${app}#g" | $SED "s/_%%enter_/\n/g" | $SED "s/lefth://g" > ${tmp_dir}/${app}/lefth
        sudo -u small-shell $ROOT/bin/DATA_shell authkey:${authkey} databox:${app}.UI.md.def action:set id:${id} key:lefth input_dir:${tmp_dir}/${app}
      fi

       target=`echo $bkup | awk -F ".org" '{print $1}'`
       cat ${www}/descriptor/common_parts/${target} | $SED "s#${cluster_base_url}${app}#./${app}#g" > ${tmp_dir}/${target}.menu
       cat ${tmp_dir}/${target}.menu > ${www}/descriptor/common_parts/${target}
    done


    # restore index
    for target in `ls ${www}/html | grep -v index | xargs basename -a`
    do  
      if [ -f ${www}/html/${target}/index.html ];then
        cat ${www}/html/${target}/index.html | $SED "s#${cluster_base_url}#${base_url}#g" > ${tmp_dir}/${target}.index.html
        cat ${tmp_dir}/${target}.index.html > ${www}/html/${target}/index.html
        if [ -f ${cgidir}/_${target} ];then
          cat $ROOT/web/src/descriptor/redirect.html.def | $SED "s#%%APPURL#${base_url}${target}#g" > ${www}/html/${target}/index.html
          mv ${cgidir}/_${target} ${cgidir}/${target}
        fi
      fi
    done 

    chown -R small-shell:small-shell ${www}/descriptor
    chown -R small-shell:small-shell ${www}/html

    # purge authorized key
    rm -f /home/small-shell/.ssh/authorized_keys

    echo ""
    echo "---------------------------------------------------------------"
    echo "Replication is successfully purged."
    echo "---------------------------------------------------------------"
    echo "Replication setting has been removed on this server, you need to to exec \"mkrep.sh purge\" on master server as well."
    echo ""

  fi

fi

if [ ! "$param" = "reg.master" -a ! "$param" = "reg.replica" -a ! "$param" = "purge" -a ! "$param" = "show.pub" ];then
  if [ "$param" ];then
    echo "$param is wrong option"
  else
    echo "please set option"
  fi
fi

rm -rf $tmp_dir
exit 0
