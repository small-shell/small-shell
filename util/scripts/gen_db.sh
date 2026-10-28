#!/bin/bash

#---------------------------------------------------------------------
# usage: gen_db.sh $db.def
#----------------------------------------------------------------------

db_def=$1

WHOAMI=$(whoami)
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# load env
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../../.env

if [ ! "$db_def" ];then
  echo "error: please input db.def for making databox #./gen_db.sh \$db.def"
  exit 1
fi

if [ ! -f $db_def ];then
  echo "error: $db_def does not exist"
  exit 1
fi

# mk tmpdir
rand=$RANDOM
tmp_dir=${ROOT}/util/scripts/tmp/gen_db_${rand}
while [ -d $tmp_dir ]
do
  rand=$RANDOM
  tmp_dir=${ROOT}/util/scripts/tmp/gen_db_${rand}
done
mkdir $tmp_dir

# remove win enter code
cat $db_def | tr -d '\r' > ${tmp_dir}/.db.def
db_def=${tmp_dir}/.db.def

# gen tmp/db.def
cat $db_def | grep "^databox="  | $SED "s/databox=//g" | $SED "s/\"//g"  > ${tmp_dir}/db.def

primary_key=$(cat $db_def | grep "^primary_key=" | cut -d '=' -f 2- | $SED "s/\"//g")
if [ "$primary_key" = "hashid" ];then
  # not need to define primary key
  echo "no" >> ${tmp_dir}/db.def
else
  # define primary key
  echo "yes" >> ${tmp_dir}/db.def
  cat $db_def | grep "^primary_key" | cut -d '=' -f 2- | $SED "s/\"//g" >> ${tmp_dir}/db.def
  echo "yes" >> ${tmp_dir}/db.def
fi

# load cols
col_num=$(cat $db_def | grep "^+addcol" | wc -l)
((col_num += 1))

count=2
while [ $count -le $col_num ]
do
  cat $db_def | grep "^col${count}_" | $SED "s/col${count}_//g" > ${tmp_dir}/.col${count}
  line_num=$(cat ${tmp_dir}/.col${count} | wc -l)
  if [ $line_num -gt 6 ];then
    echo "col${count} seems too much definition"
    exit 1
  fi

  # load columns
  chmod 755 ${tmp_dir}/.col${count}
  . ${tmp_dir}/.col${count} 2>/dev/null

  if [ ! $? -eq 0 ];then
    echo "error: failed to load col${count} params"
    exit 1
  fi

  if [ ! "$key_name" ];then
    echo "error: col${count} please define key name"
    exit 1
  fi

  if [ ! "$key_label" ];then
    echo "error: col${count} please define label name"
    exit 1
  fi

  if [ ! "$required" = "yes" -a  ! "$required" = "no" ];then
    if [ ! "$type" = "file" -a ! "$type" = "checkbox" -a ! "$type" = "radio" -a ! "$type" = "select" ];then
      echo "error: col${count} please define required yes or no"
      exit 1
    fi
  fi

  value_chk=$(cat ${tmp_dir}/.col${count} | grep -A 1 "type=\"${type}\"" \
  | grep values= | $SED "s/values=//g" | $SED "s/\"//g")
  if [ "$type" = "select" -o "$type" = "radio" ];then
    if [ ! "$value_chk" ];then
      echo "error: please define values after select or radio"
      exit 1
    fi
  else
    if [ "$value_chk" ];then
      echo "error: $type could not define values"
      exit 1
    fi
  fi

  param_chk=$(cat ${tmp_dir}/.col${count} | grep -A 2 "type=\"${type}\"" \
  | grep primary_databox= | $SED "s/primary_databox=//g" | $SED "s/\"//g")
  if [ "$type" = "pdls" ];then
    if [ ! "$param_chk" ];then
      echo "error: please define primary_databox for pdls "
      exit 1
    fi
  else
    if [ "$param_chk" ];then
      echo "error: $type could not define primary_databox"
      exit 1
    fi
  fi

  type_chk=$(cat $db_def \
  | grep -e "col${count}_type=\"checkbox\"" -e "col${count}_type=\"select\"" -e "col${count}_type=\"radio\"" -e "col${count}_type=\"file\"")

  if [ ! "$type_chk" ];then
    cat $db_def | grep "^col${count}_" | cut -d '=' -f 2- | $SED "s/\"//g" | $SED "/^$/d" >> ${tmp_dir}/db.def
  else 
    cat $db_def | grep "^col${count}_" | grep -v col${count}_required= | cut -d '=' -f 2- \
    | $SED "s/\"//g" | $SED "/^$/d" >> ${tmp_dir}/db.def
  fi
  
  if [ $count -lt $col_num ];then
    # add more column
    echo "yes" >> ${tmp_dir}/db.def
  else
    echo "no" >> ${tmp_dir}/db.def
  fi

  ((count += 1))
done

# add fin answer
echo "yes" >> ${tmp_dir}/db.def

cat ${tmp_dir}/db.def | ${ROOT}/adm/gen -databox -bat

exit 0
