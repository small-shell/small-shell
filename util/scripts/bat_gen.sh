#!/bin/bash

#---------------------------------------------------------------------
# usage: bat_gen.sh $db.def
#----------------------------------------------------------------------

db_def=$1

WHOAMI=`whoami`
if [ ! "$WHOAMI" = "root" ];then
  echo "error: user must be root"
  exit 1
fi

# global.conf load
SCRIPT_DIR=`dirname $0`
. ${SCRIPT_DIR}/../../global.conf

if [ ! "$db_def" ];then
  echo "error: please input db.def for making databox #./bat_gen.sh $db.def"
  exit 1
fi

if [ ! -f $db_def ];then
  echo "error: $db_def does not exist"
  exit 1
fi

# global conf load
SCRIPT_DIR=`dirname $0`
 . ${SCRIPT_DIR}/../../global.conf

# gen tmp/db.def.load
cat $db_def | grep "^databox="  | $SED "s/databox=//g" | $SED "s/\"//g"  > $ROOT/util/scripts/tmp/db.def.load

primary_key=`cat $db_def | grep "^primary_key=" | cut -d '=' -f 2- | $SED "s/\"//g"`
if [ "$primary_key" = "hashid" ];then
  #exclude label
  cat $db_def | grep "^primary_key=" | cut -d '=' -f 2- | $SED "s/\"//g" >> $ROOT/util/scripts/tmp/db.def.load
else
  #include label
  cat $db_def | grep "^primary_key" | cut -d '=' -f 2- | $SED "s/\"//g" >> $ROOT/util/scripts/tmp/db.def.load
  echo "yes" >> $ROOT/util/scripts/tmp/db.def.load
fi


# load cols
col_num=`cat $db_def | grep "^+addcol" | wc -l`
((col_num += 1))

count=2
while [ $count -le $col_num ]
do
  cat $db_def | grep "^col${count}_" | $SED "s/col${count}_//g" > $ROOT/util/scripts/tmp/.col${count}
  line_num=`cat $ROOT/util/scripts/tmp/.col${count} | wc -l`
  if [ $line_num -gt 6 ];then
    echo "col${count} seems too much definition"
    exit 1
  fi

  # load columns
  chmod 755 $ROOT/util/scripts/tmp/.col${count}
  . $ROOT/util/scripts/tmp/.col${count} 2>/dev/null

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

   param_chk=`cat $ROOT/util/scripts/tmp/.col${count} | grep -A 1 "type=\"$type\"" \
  | grep key_params= | $SED "s/key_params=//g" | $SED "s/\"//g"`
  if [ "$type" = "select" -o "$type" = "radio" ];then
    if [ ! "$param_chk" ];then
      echo "error: please define params after select or radio"
      exit 1
    fi
  else
    if [ "$param_chk" ];then
      echo "error: $type could not define parameters"
      exit 1
    fi
  fi

  param_chk=`cat $ROOT/util/scripts/tmp/.col${count} | grep -A 2 "type=\"$type\"" \
  | grep primary_databox= | $SED "s/primary_databox=//g" | $SED "s/\"//g"`
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

  type_chk=`cat $db_def \
  | grep -e "col${count}_type=\"checkbox\"" -e "col${count}_type=\"select\"" -e "col${count}_type=\"radio\"" -e "col${count}_type=\"file\""`  

  if [ ! "$type_chk" ];then
    cat $db_def | grep "^col${count}_" | cut -d '=' -f 2- | $SED "s/\"//g" | $SED "/^$/d" >> $ROOT/util/scripts/tmp/db.def.load
  else 
    cat $db_def | grep "^col${count}_" | grep -v col${count}_required= | cut -d '=' -f 2- \
    | $SED "s/\"//g" | $SED "/^$/d" >> $ROOT/util/scripts/tmp/db.def.load
  fi
  
  if [ $count -lt $col_num ];then
    # add more column
    echo "yes" >> $ROOT/util/scripts/tmp/db.def.load
  else
    echo "no" >> $ROOT/util/scripts/tmp/db.def.load
  fi

  ((count += 1))
done

# add fin answer
echo "yes" >> $ROOT/util/scripts/tmp/db.def.load

cat $ROOT/util/scripts/tmp/db.def.load | $ROOT/adm/gen -databox -bat

exit 0
