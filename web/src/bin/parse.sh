#!/bin/bash

session=$1
type=$2
input=%%www/tmp/${session}/input

# load env
. %%www/def/.env


if [ "$type" = "urlenc" ];then
  cat $input | $SED "s/\`//g" | $SED "s/\&/_%%separator_/g" | $PHP -r "echo urldecode(file_get_contents('php://stdin'));" \
  | $SED -z "s/\n/_%%enter_/g" |  $SED "s/\$/\n/g" | $SED "s/_%%separator_/\n/g" \
  | $SED "s/=/_%%equal_/1"  | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));" > %%www/tmp/${session}/params

  while IFS= read line
  do
    param_name=$(echo "$line" | $AWK -F "_%%equal_" '{print $1}')
    meta_chk_result=$(echo "$param_name" | grep -e " " -e "," -e "\!" -e "\*" -e "=" -e "(" -e ")" -e "\\\\" -e "/" \
    -e ":" -e ";" -e "&" -e "\"" -e "\\$" -e "%" -e "'" -e "\`" -e "#" -e "~" -e \| -e ">" -e "<")

    if [ "$meta_chk_result" ];then
      param_name=null
    fi

    param_value=$(echo "$line" | $AWK -F "_%%equal_" '{print $2}')
    echo "$param_value" |  tr -d \\\r | $SED "s/_%%enter_/\n/g" >> %%www/tmp/${session}/${param_name}
  done < %%www/tmp/${session}/params

  rm -rf %%www/tmp/${session}/input
  rm -rf %%www/tmp/${session}/params
fi

if [ "$type" = "multipart" ];then
  line_num=0
  sub_line_num=0

  if [ ! -d %%www/tmp/${session}/binary_file ];then
    mkdir %%www/tmp/${session}/binary_file
  fi

  # get boundary
  boundary=$(head -1 $input | $SED -r "s/^(-*)//g" | $SED "s/.$//g")

  # get params
  grep -a "Content-Disposition: form-data; name=" $input | $AWK -F "name=" '{print $2}' | $AWK -F "\"" '{print $2}' > %%www/tmp/${session}/params

  # remove binary data
  file_chk=$(grep -a "Content-Disposition: form-data; name=" %%www/tmp/${session}/input | grep -a "filename=")
  file_num_chk=$(echo "$file_chk" | wc -l | tr -d " ")
  if [ $file_num_chk -gt 1 ];then 
    echo "error: file_input must be only 1"
    exit 1
  fi

  if [ "$file_chk" ];then
    grep -n -a -e "$boundary" -e "Content-Disposition: form-data;" %%www/tmp/${session}/input > %%www/tmp/${session}/temp1
    binary_line_start=$(grep "filename=" %%www/tmp/${session}/temp1 | $AWK -F ":" '{print $1}')
    binary_line_end=$(grep -A 1 "filename="  %%www/tmp/${session}/temp1 | grep "$boundary" | $AWK -F ":" '{print $1}')
    binary_file_name=$(grep -a "Content-Disposition: form-data; name=" %%www/tmp/${session}/temp1 | grep filename= \
    | $AWK -F "filename=" '{print $2}' | $AWK -F "\"" '{print $2}'| tr -d \\\r)

    input_name=$(grep -a "Content-Disposition: form-data; name=" %%www/tmp/${session}/temp1 | grep filename= \
    | $AWK -F "name=" '{print $2}' | $AWK -F "\"" '{print $2}'| tr -d \\\r)

    binary_line_start=$(expr $binary_line_start + 3)
    binary_line_end=$(expr $binary_line_end - 1)

    # detouch text line
    $SED ${binary_line_start},${binary_line_end}d  %%www/tmp/${session}/input \
    | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));" | tr -d \\\r  > %%www/tmp/${session}/temp2
    input=%%www/tmp/${session}/temp2

    # binary data parse
    $SED -n ${binary_line_start},${binary_line_end}p %%www/tmp/${session}/input > %%www/tmp/${session}/binary_file/binary.data
    echo "$binary_file_name" > %%www/tmp/${session}/binary_file/file_name
    echo "$input_name" > %%www/tmp/${session}/binary_file/input_name
  fi


  # text line parse
  while IFS= read line
  do
    line_num=$(expr $line_num + 1)
    sub_line_num=$(expr $sub_line_num + 1)

    if [ "$(echo "$line" | grep "$boundary")" ];then
      sub_line_num=1
    fi

    if [ "$(echo "$line" | grep "Content-Disposition: form-data")" ];then
      for param in $(cat %%www/tmp/${session}/params)
      do
        if [ "$(echo "$line" | grep "${param}")" ];then
          name=$param
          meta_chk_result=$(echo "$name" | grep -e " " -e "," -e "\!" -e "\*" -e "=" -e "(" -e ")" -e "\\\\" -e "/" \
           -e ":" -e ";" -e "&" -e "\"" -e "\\$" -e "%" -e "'" -e "\`" -e "#" -e "~" -e \| -e ">" -e "<")
          if [ "$meta_chk_result" ];then
            name=null
          fi
        fi
      done
      sub_line_num=2
    fi

    if [ "$(echo "$line" | grep "Content-Type: application/octet-stream")" ];then
      file=yes
    fi

    if [ "$sub_line_num" -gt 3 ];then
      if [ ! "$file" = "yes" ];then
        echo "$line" | tr -d \\\r  >> %%www/tmp/${session}/${name}
      else
        file=no
      fi
    fi

  done < $input

  rm -rf %%www/tmp/${session}/temp*
  rm -rf %%www/tmp/${session}/input
  rm -rf %%www/tmp/${session}/params
fi

if [ "$type" = "data-binary" ];then
  mkdir %%www/tmp/${session}/binary_file
  cp $input %%www/tmp/${session}/binary_file/binary.data
  rm -rf %%www/tmp/${session}/input
fi

if [ "$type" = "json" ];then
  # load keys 
  keys=$(cat $input | $JQ 'keys' | $JQ -r .[])
  for key in $keys
  do
    JQ_EXE="cat $input | $JQ -r '.$key'"
    eval $JQ_EXE >  %%www/tmp/${session}/${key}
  done
  rm -rf %%www/tmp/${session}/input
fi

exit 0
