#!/bin/bash
#---------------------------------------------------------------------
# usage: gen_container_app.sh $app.def
#----------------------------------------------------------------------

app_def=$1

WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# load env
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env

if [ ! "$app_def" ];then
  echo "error: please input app.def #./gen_container_app.sh app.def"
  exit 1
fi

# mk tmpdir
rand=$RANDOM
tmp_dir=${ROOT}/util/scripts/tmp/gen_app_${rand}
while [ -d $tmp_dir ]
do
  rand=$RANDOM
  tmp_dir=${ROOT}/util/scripts/tmp/gen_app_${rand}
done
mkdir $tmp_dir

load_def="${tmp_dir}/app.def.load"
gen_def="${tmp_dir}/app.def"

# gen tmp/app.def.load
cat $app_def | tr -d '\r'  > $load_def
chmod 755 $load_def
. $load_def

if [ ! $? -eq 0 ];then
  echo "error: failed to load $app_def params"
  exit 1
fi

# gen Base App
if [ "$server" ];then
  echo "1" > $gen_def
  echo "1" >> $gen_def

  if [ ! "$port" ];then
    echo "error: please set port for making Base App"
    exit 1
  fi

  if [ "$port" = "http" ];then
    port="80"
  fi

  if [ "$port" = "https" ];then
     port="443"
  fi

  if [ "$ssl_cert_path" ];then
    protocol="https"
    echo "$protocol" >> $gen_def
    if [ -f "/var/www/app/cert.pem" ];then
      # not reuse current cert
      echo "no" >> $gen_def
    fi 
    if [ -f "$ssl_cert_path" ];then
      echo "$ssl_cert_path" >> $gen_def
    else
      echo "error: ssl cert path seems wrong"
      exit 1
    fi
    if [ -f "$ssl_private_key_path" ];then
      echo "$ssl_private_key_path" >> $gen_def
    else
      echo "error: ssl private key path seems wrong"
      exit 1
    fi
    if [ "$chain_cert_path" ];then
      # use chain cert
      echo "yes" >> $gen_def
      if [ -f "$chain_cert_path" ];then
        echo "$chain_cert_path" >> $gen_def
      else
        echo "error: ssl chain cert path seems wrong"
        exit 1
      fi
    else
      # not use chain cert
      echo "no" >> $gen_def
    fi
    echo "$server" >> $gen_def
    echo "$port" >> $gen_def
    echo "yes" >> $gen_def
  else
    protocol="http"
    echo "$protocol" >> $gen_def
    echo "$server" >> $gen_def
    echo "$port" >> $gen_def
    echo "yes" >> $gen_def
  fi


  # gen app
  cat $gen_def| ${ROOT}/adm/gen -app -container
  cat ${ROOT}/util/scripts/.post_processing_module_for_container | $SED "s/%%app_type/1/g" > /var/tmp/post_processing.sh
  chmod 755 /var/tmp/post_processing.sh
fi

# gen Form
if [ "$form_name" ];then
  gen_def="${tmp_dir}/app_form.def"

  if [ ! -f ${ROOT}/web/base ];then
    echo "error: you need to generate Base App first"
    exit 1 
  fi

  if [ ! "$form_title" ];then
    echo "error: please set form title for external form"
    exit 1
  fi

  if [ ! "$databox_for_external_form" ];then
    echo "error: please set databox name for external form"
    exit 1
  fi

  if [ ! -d ${ROOT}/databox/${databox_for_external_form} ];then
    echo "error: there is no databox:${databox_for_external_form}"
    exit 1
  fi

  if [ ! "$description" ];then
    echo "error: please set description for external form"
    exit 1
  fi

  if [ ! "$keys" ];then
    echo "error: please set keys for external form"
    exit 1
  fi

  echo "2" > $gen_def
  echo "$form_name" >> $gen_def
  echo "$form_title" >> $gen_def
  echo "$databox_for_external_form" >> $gen_def
  echo "$description" >> $gen_def

  # key check
  keys=$(echo "$keys" | $SED "s/,/\n/g" | sort | uniq | $SED -z "s/\n/ /g" | $SED "s/ $//g")
  key_count=$(echo "$keys" | $SED "s/ /\n/g" | grep -v hashid | wc -l)
  col_count=$(grep name= ${ROOT}/databox/${databox_for_external_form}/def/* | grep -v hashid | wc -l)
  if [ $key_count -gt $col_count ];then
    echo "error: it seems number of key is too much" 
    exit 1
  fi

  count=1
  for key in $keys
  do
    key_chk=$(grep "name=\"$key\"" ${ROOT}/databox/${databox_for_external_form}/def/*)
    if [ ! "$key_chk" ];then
      echo "error: it seems there is no key:$key in $databox_for_external_form"
      exit 1
    else
      echo "$key" >> $gen_def
    fi

    if [ $count -lt $key_count ];then
        echo "yes" >> $gen_def
    else
      if [ $count -lt $col_count ];then
        echo "no" >> $gen_def
      fi
    fi

    ((count++))
  done
  echo "yes" >> $gen_def

  # gen app
  cat $gen_def| ${ROOT}/adm/gen -app -container

fi

# gen Custm App
if [ "$app_name" ];then

  if [ ! "$databox_for_custom_app" ];then
    echo "error: please set databox name for custom app"
    exit 1
  fi

  if [ ! "$databox_for_custom_app" = "none" -a ! -d ${ROOT}/databox/${databox_for_custom_app} ];then
    echo "error: there is no databox:${databox_for_custom_app}"
    exit 1
  fi

  if [ ! "$auth_type" ];then
    echo "error: please set auth type for custom app"
    exit 1
  fi

  echo "3" > $gen_def
  echo "$app_name" >> $gen_def
  if [ ! -f ${ROOT}/web/base ];then
    echo "error: you need to generate Base App first"
  fi

  if [[ "$auth_type" =~ ^[0-9]+$ ]]; then

    if [ $auth_type -gt 4 ];then
      echo "error: authentication type must be 1 to 4"
      exit 1
    fi

  elif [ auth_type = "shared pass" ];then
    auth_type=1
  elif [ auth_type = "user key" ];then
    auth_type=2
  elif [ auth_type = "other" ];then
    auth_type=3
  elif [ auth_type = "none" ];then
    auth_type=4

  else
    echo "error: authentication type is not correct"
    exit 1
  fi


  echo "$auth_type" >> $gen_def
  if [ $auth_type -eq 1 ];then
    if [ ! "$shared_pass" ];then
      echo "error: plesae set shared pass code"
      exit 1
    fi
    num_value_chk=$(echo "$shared_pass" | $SED "s/[0-9]//g" | $SED "s/-//g")
    value_chk=$(echo "$shared_pass" | $SED -z "s/\n//g")
    if [ "$shared_pass" -a "$num_value_chk" ];then
      echo "error: shared pass code must be numetric character"
      exit 1
    fi
    echo "$shared_pass" >> $gen_def
  fi

  echo "$databox_for_custom_app" >> $gen_def
  echo "yes" >> $gen_def
  cat $gen_def | ${ROOT}/adm/gen -app -container
  cat ${ROOT}/util/scripts/.post_processing_module_for_container | $SED "s/%%app_type/3/g" \
  | $SED "s/%%app_name/$app_name/g" | $SED "s/%%auth_type/$auth_type/g" \
  | $SED "s/%%databox_for_custom_app/$databox_for_custom_app/g" \
  > /var/tmp/post_processing.sh
  chmod 755 /var/tmp/post_processing.sh
fi

# gen Sub App
if [ "$additional_databoxes" ];then
  parent_app=$app_name
  if [ ! "$app_name" ];then
    echo "please set app name"
    exit 1
  fi

  if [ ! -f ${ROOT}/web/base ];then
    echo "error: you need to generate Base App first"
    exit 1
  else
    . ${ROOT}/web/base
  fi

  if [ ! -f ${www}/cgi-bin/${parent_app} ];then
    echo "error: there is no app:${parent_app}"
    exit 1
  fi


  sub_app_names=""
  for databox_for_sub_app in $( echo $additional_databoxes | $SED "s/,/ /g" )
  do 
    if [ ! -d ${ROOT}/databox/${databox_for_sub_app} ];then
      echo "error: there is no databox:${databox_for_sub_app}"
      exit 1
    fi

    sub_app_name="sub_${RANDOM}.${parent_app}"
    while [ -d ${www}/bin/${sub_app_name}_bin_get.sh ]
    do
      sub_app_name="sub_${RANDOM}.${parent_app}"
    done 
    gen_def_for_sub="${tmp_dir}/${sub_app_name}.def"
    echo "${sub_app_name}:${databox_for_sub_app}" >> /var/tmp/.additional_databoxes
    echo "3" > $gen_def_for_sub
    echo "${sub_app_name}@${parent_app}" >> $gen_def_for_sub
    echo "${databox_for_sub_app}" >> $gen_def_for_sub
    echo "yes" >> $gen_def_for_sub
    cat $gen_def_for_sub | ${ROOT}/adm/gen -app -container
    if [ "$sub_apps" ];then
      sub_apps="${sub_apps},${sub_app_name}"
    else
      sub_apps="${sub_app_name}"
    fi
  done

  if [ -f /var/tmp/post_processing.sh ];then
    sed -i "s/%%sub_apps/$sub_apps/g" /var/tmp/post_processing.sh
    sed -i "s/%%parent_app/$parent_app/g" /var/tmp/post_processing.sh
    sed -i "s/sub_app_flag=no/sub_app_flag=yes/g" /var/tmp/post_processing.sh
  else
    cat ${ROOT}/util/scripts/.post_processing_module_for_container | $SED "s/%%sub_apps/$sub_apps/g" \
    | $SED "s/%%parent_app/$parent_app/g" | $SED "s/sub_app_flag=no/sub_app_flag=yes/g" \
    > /var/tmp/post_processing.sh
  fi

  chmod 755 /var/tmp/.additional_databoxes
  chmod 755 /var/tmp/post_processing.sh

fi

exit 0
