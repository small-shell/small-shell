#!/bin/bash

# load params
app=$1
session=$2
pin=$3

# load small-shell conf
. %%www/descriptor/.small_shell_conf

# set basic params
tmp=%%www/tmp/${session}
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:$app"

# load mark down definition
databox=${app}.UI.md.def
id=`$DATA_SHELL databox:${databox} command:head_-1 format:none | $AWK -F "," '{print $1}'`
$DATA_SHELL databox:${databox} action:get id:$id key:description format:none \
| $SED "s/description://g" | ${SED} "s/_%%enter_/\n/g" > ${tmp}/description.md
source=${tmp}/description.md

# parse markdown
cat $source | $SED "s/^:::/{%%%}{%%%}{%%%}/g" | $SED "s/\`\`\`\`/%code_block%/g" \
| $SED "s/\\t/_%%tab_/g" | $SED "s/^    /_%%4space_/g" | $SED "s/^ /_%%space_/g" > ${tmp}/.description.md
echo "" >> ${tmp}/.description.md
source=${tmp}/.description.md

while read line
do
   # code
   if [[ "$line" == "%code_block%" ]];then 
     if [ ! "$code_flg"  ];then
       echo -n "<pre class=\"code\">" >> ${tmp}/description.tmp 
       code_flg=yes
     else
       echo "</pre>" >> ${tmp}/description.tmp
       code_flg=""
     fi 

   elif [[ "$code_flg" == "yes" && "$tab_4space" == "" ]];then
       echo "$line" | $SED "s/_%%tab_/\\t/g" | $SED "s/_%%space_/ /g" | $SED "s/_%%4space_/    /g" \
       | $SED "s/{%%%}{%%%}{%%%}/:::/g"  >> ${tmp}/description.tmp

   elif [[ "$line" == %%_tab_* || "$line" == _%%4space_* ]];then 
     if [ ! "$code_flg" ];then 
       tab_4space=yes
       code_flg=yes 
       echo -n "<pre class=\"code\"><code>" >> ${tmp}/description.tmp 
       echo "$line" | $SED "s/_%%tab_//g" | $SED "s/_%%4space_//g" | $SED "s/{%%%}{%%%}{%%%}/:::/g" >> ${tmp}/description.tmp
     elif [ "tab_4space" -a "$code_flg" ];then
       echo "$line" | $SED "s/_%%tab_//g" | $SED "s/_%%4space_//g" | $SED "s/{%%%}{%%%}{%%%}/:::/g" >> ${tmp}/description.tmp
     fi

   elif [[ "$line" == "" && "$code_flg" == "yes" && "$tab_4space" == "yes" ]];then
      echo "</code></pre>" >> ${tmp}/description.tmp
      code_flg=""
      tab_4space=""


   # Extension code
   elif [[ "$line" == {%%%}{%%%}{%%%}* ]];then 
     if [ ! "$extension_code" ];then
       extension_code=yes
       if [[ "$line" == *Warning* ]];then 
         echo "<pre class=\"warning\"><b>!Warning</b>" >> ${tmp}/description.tmp
       else
         echo "<pre class=\"note\"><b>!Note</b>" >> ${tmp}/description.tmp
       fi
     else
      echo "</pre>" >> ${tmp}/description.tmp
      extension_code=""
     fi

   elif [[ "$extension_code" == "yes" ]];then
     echo "$line" >> ${tmp}/description.tmp

   #table
   elif [[ "$line" == \|*\|* ]];then
     if [ ! "$table_flg" ];then
       table_flg=yes
       echo "<div class=\"flex-table\">" >> ${tmp}/description.tmp
       echo "<ul>" >> ${tmp}/description.tmp
       echo "<li class=\"flex-table-header\">" >> ${tmp}/description.tmp
       echo "$line" | $SED "s/|/<p>/1" | $SED "s/|/<\/p><p>/g" | $SED "s/<p>$/\n<\/li>/g" >> ${tmp}/description.tmp
     else
       echo "$line" | $SED "s/|/<li><p>/1" | $SED "s/|/<\/p><p>/g" | $SED "s/<p>$/<\/li>/g" >> ${tmp}/description.tmp
     fi

   elif [[ "$line" == --* && "$table_flg" == "yes" ]];then
      echo "" > /dev/null

   elif [[ "$line" != \|*\|* && "$table_flg" == "yes" ]];then
      echo "</ul>" >> ${tmp}/description.tmp
      echo "</div>" >> ${tmp}/description.tmp
      table_flg=""
  
   # link
   elif [[ "$line" == *\[*\]\(*\)* ]];then
     element_l=`echo "$line" | $AWK -F "[" '{print $1}'`
     tag=`echo "$line" | $AWK -F "[" '{print $2}' | $SED -r "s/](.*)//g"`
     url=`echo "$line" | $AWK -F "(" '{print $2}' | $SED -r "s/\)(.*)//g"`
     element_r=`echo "$line" | $AWK -F ")" '{print $2}'`
     echo "<p>$element_l <a href=\"$url\">$tag</a> $element_r</p>" >> ${tmp}/description.tmp

   # button 
   elif [[ "$line" == *\[*\]* ]];then
     echo "$line" | $SED "s/\[/<button>/1" | $SED "s/\]/<\/button>/1" >> ${tmp}/description.tmp

   # bold 
   elif [[ "$line" == *\**\** ]];then
     new_line=`echo "$line" | $SED "s/\*/<b>/1" | $SED "s/\*/<\/b>/1"` 

     while [[ "$new_line" == *\** ]]
     do
       new_line=`echo "$new_line" | $SED "s/\*/<b>/1" | $SED "s/\*/<\/b>/1"` 
     done
     echo "$new_line" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" >> ${tmp}/description.tmp

   # list
   elif [[ "$line" == \** ]];then
     if [ ! "$list_flg" ];then
       list_flg=yes
       echo "<div class=\"standard-list\">" >> ${tmp}/description.tmp
       echo "<ul>" >> ${tmp}/description.tmp
       echo  "$line" | $SED "s/\*/<li>/1" | $SED "s/$/<\/li>/g" >> ${tmp}/description.tmp
     else
       echo  "$line" | $SED "s/\*/<li>/1" | $SED "s/$/<\/li>/g" >> ${tmp}/description.tmp
     fi
   elif [[ "$line" != \** && "$list_flg" == "yes" ]];then
       echo "</ul>" >> ${tmp}/description.tmp
       echo "</div>" >> ${tmp}/description.tmp
       list_flg=""

   #HN
   elif [[ "$line" == \#\#\#\#\#\#* ]];then
     echo "$line" | $SED "s/^######/<h6>/1" | $SED "s/$/<\/h6>/g" | $SED "s/######//g" >> ${tmp}/description.tmp

   elif [[ "$line" == \#\#\#\#\#* ]];then
     echo "$line" | $SED "s/#####/<h5>/1" | $SED "s/$/<\/h5>/g" |  $SED "s/######//g" >> ${tmp}/description.tmp

   elif [[ "$line" == \#\#\#\#* ]];then
     echo "$line" | $SED "s/####/<h4>/1" | $SED "s/$/<\/h4>/g" | $SED "s/####//g" >> ${tmp}/description.tmp

   elif [[ "$line" == \#\#\#* ]];then
     echo "$line" | $SED "s/###/<h3>/1" | $SED "s/$/<\/h3>/g" | $SED "s/###//g" >> ${tmp}/description.tmp

   elif [[ "$line" == \#\#* ]];then
     hashlink=`echo $line | $SHASUM | $AWK '{print $1}'`
     echo "$line" | $SED "s/## /<h2 id=\"$hashlink\">/1" | $SED "s/$/<\/h2>/g" | $SED "s/## //g" >> ${tmp}/description.tmp
     echo "$line" | $SED "s/## /<a href=\"#$hashlink\"><p>/1" | $SED "s/$/<\/p><\/a>/g" | $SED "s/## //g" >> ${tmp}/leftnav.tmp

   elif [[ "$line" == \#* ]];then
     if [ ! "$home_flg" ];then
       home_flg=yes
       echo "$line" | $SED "s/# /<h1 id=\"HOME\">/1" | $SED "s/$/<\/h1>/g" | $SED "s/# //g" >> ${tmp}/description.tmp
       echo "<a href=\"#HOME\"><p>HOME</p></a>" >> ${tmp}/leftnav.tmp
     else
       hashlink=`echo $line | $SHASUM | $AWK '{print $1}'`
       echo "$line" | $SED "s/# /<h1 id=\"$hashlink\">/1" | $SED "s/$/<\/h1>/g" | $SED "s/# //g" >> ${tmp}/description.tmp
       echo "$line" | $SED "s/# /<a href=\"#$hashlink\"><p>/1" | $SED "s/$/<\/p><\/a>/g" | $SED "s/# //g" >> ${tmp}/leftnav.tmp
     fi 

   # html tag
   elif [[ "$line" == \<*\> ]];then
     echo "$line" >> ${tmp}/description.tmp

   # No tag
   else
     if [ ! "$line" = "" ];then
       echo "$line" | $SED "s/_%%space_/ /g" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" \
      | $SED "s/{%%%}{%%%}{%%%}/:::/g"  >> ${tmp}/description.tmp
     fi
   fi
done  < $source

# handle right header
righth=`$META chk.null:${databox}{$id} | grep righth | $AWK -F ":" '{print $2}'`
if [ $righth -eq 1 ];then
  echo "<div class=\"right-header\">" > ${tmp}/righth.tmp
  echo "<button class=\"even-btn-menu\">=</button>" >> ${tmp}/righth.tmp
  echo "<nav>" >> ${tmp}/righth.tmp
  echo "<ul>" >> ${tmp}/righth.tmp
  $DATA_SHELL databox:${databox} action:get id:$id key:righth format:none \
  | $SED "s/righth://g" | ${SED} "s/_%%enter_/\n/g" > ${tmp}/righth_raw.data

  while read r_line
  do
    tag=`echo "$r_line" |$AWK -F ":" '{print $1}'`
    url=`echo "$r_line" |cut -f 2- -d ":"`
    echo "<li><a href=\"$url\">$tag</a></li>" >> ${tmp}/righth.tmp
  done < ${tmp}/righth_raw.data

  echo "</nav>" >> ${tmp}/righth.tmp
  echo "</ul>" >> ${tmp}/righth.tmp
  echo "</div>" >> ${tmp}/righth.tmp
else
  echo "<!-- no right header-->" > ${tmp}/righth.tmp
fi

# handle left header
lefth=`$META chk.null:${databox}{$id} | grep lefth | $AWK -F ":" '{print $2}'`
if [ $lefth -eq 1 ];then
  $DATA_SHELL databox:${databox} action:get id:$id key:lefth format:none \
  | $SED "s/lefth://g" | ${SED} "s/_%%enter_/\n/g" > ${tmp}/lefth_raw.data
  while read l_line
  do
    tag=`echo "$l_line" |$AWK -F ":" '{print $1}'`
    url=`echo "$l_line" |cut -f 2- -d ":"`
    echo "<h2><a href=\"$url\">$tag</a></h2>" >> ${tmp}/lefth.tmp
  done < ${tmp}/lefth_raw.data
else
  echo "<!-- no left header-->" > ${tmp}/lefth.tmp
fi

# handle logo
logo=`$META chk.null:${databox}{$id} | grep logo | $AWK -F ":" '{print $2}'`
if [ "$logo" -eq 1 ];then
  filename=`$DATA_SHELL databox:${databox} action:get id:$id key:logo format:none | $SED "s/logo://g" | $AWK '{print $1}'`
  if [ "$filename" ];then
    # dump
    ${small_shell_path}/bin/dl databox:${databox} id:$id session:$session pin:$pin app:$app > %%www/html/${filename}
    cat ${tmp}/leftnav.tmp | grep -v "<p>HOME</p>" > ${tmp}/leftnav.tmp.1
    echo "<a href=\"#HOME\"><img src=\"../${filename}\" width=\"75%\"></a>" > ${tmp}/logo.tmp

    if [ ! -s ${tmp}/leftnav.tmp.1 ];then
      cat ${tmp}/logo.tmp > ${tmp}/leftnav.tmp.2
    else
      $SED -e "1i `cat ${tmp}/logo.tmp`" ${tmp}/leftnav.tmp.1 > ${tmp}/leftnav.tmp.2
    fi
    cat ${tmp}/leftnav.tmp.2 > ${tmp}/leftnav.tmp
  fi

fi

# handle footer
footer=`$META chk.null:${databox}{$id} | grep footer | $AWK -F ":" '{print $2}'`

if [ $footer -eq 1 ];then
  $DATA_SHELL databox:${databox} action:get id:$id key:footer format:none \
  | $SED "s/footer://g" | ${SED} "s/_%%enter_/\n/g" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" > ${tmp}/footer.tmp
else
  echo "<!-- no footer-->" > ${tmp}/footer.tmp
fi

cat %%www/descriptor/${app}_main.html.incmd.def | $SED -r "s/^( *)</</1" \
| $SED "/%%description/r ${tmp}/description.tmp" | $SED "s/%%description//g" \
| $SED "/%%leftnav/r ${tmp}/leftnav.tmp" | $SED "s/%%leftnav//g" \
| $SED "/%%righth/r ${tmp}/righth.tmp" | $SED "s/%%righth//g" \
| $SED "/%%lefth/r ${tmp}/lefth.tmp" | $SED "s/%%lefth//g" \
| $SED "/%%footer/r ${tmp}/footer.tmp" | $SED "s/%%footer//g" \
| $SED "s/?req=/?%%session\&req=/g"\
> %%www/descriptor/${app}_main.html.def

exit 0
