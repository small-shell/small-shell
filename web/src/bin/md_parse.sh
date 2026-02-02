#!/bin/bash

# load params
app=$1
session=$2
pin=$3

# load small-shell conf
. %%www/def/.small_shell_conf

# set basic params
tmp=%%www/tmp/${session}
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:$app"
DL="${small_shell_path}/bin/dl session:$session pin:$pin app:$app"

# load mark down definition
databox=${app}.UI.md.def
id=$($DATA_SHELL databox:${databox} command:head_-1 format:none | $AWK -F "," '{print $1}')
$DATA_SHELL databox:${databox} action:get id:$id key:body format:none \
| $SED "s/body://g" | ${SED} "s/_%%enter_/\n/g" > ${tmp}/body.md
source=${tmp}/body.md

# parse markdown
cat $source | $SED "s/^:::/{%%%}{%%%}{%%%}/g" | $SED "s/\`\`\`\`/%code_block%/g" | $SED "s/\`\`\`/%code_block%/g" \
| $SED "s/\\t/_%%tab_/g" | $SED "s/^    /_%%4space_/g" | $SED "s/^ /_%%space_/g" > ${tmp}/.body.md
echo "" >> ${tmp}/.body.md
source=${tmp}/.body.md

line_count=1
while read line
do
   # html tag
   if [[ "$line" == *\<*\> ]];then

     # dump image
     if [[ "$line" == *"<img src=\"../images"* ]];then

       img_id=$(echo "$line" | $AWK -F "images/" '{print $2}' | $AWK -F ">" '{print $1}' | $SED "s/\"//g")
       file_type=$($DATA_SHELL databox:images.db id:${img_id} remote_addr:localhost key:image action:get format:none \
       | $SED "s/image://g" | $AWK -F "#" '{print $1}' | $AWK -F "." '{print $NF}' | $SED "s/ //g")
       echo "$line" | $SED "s#../images/${img_id}#../images/${img_id}.${file_type}#g" >> ${tmp}/body.tmp
       $DL databox:images.db id:${img_id} remote_addr:localhost > %%www/html/images/${img_id}.${file_type}

     else
       # handle as normal HTML tag
       echo "$line" | $SED "s/_%%space_/ /g" | $SED "s/_%%4space_/    /g" >> ${tmp}/body.tmp

     fi

   # Normal list
   elif echo "$line" | grep -q -e '^- ' -e '^* ' -e '^+ '; then
     if [ ! "$extention_flg" -a ! "$code_flg" ];then
       if [ ! "$normal_list_flg" ];then
         normal_list_flg=yes
         echo "<div class=\"standard-list\">" >> ${tmp}/body.tmp
         echo "<ul>" >> ${tmp}/body.tmp
         echo  "$line" | $SED "s/^\- /<li>/1" | $SED "s/^\* /<li>/1" | $SED "s/^\* /<li>/1" \
         | $SED "s/^\+ /<li>/1" | $SED "s/$/<\/li>/g" >> ${tmp}/body.tmp
       else
         echo  "$line" | $SED "s/^\- /<li>/1" | $SED "s/^\* /<li>/1" | $SED "s/^\* /<li>/1" \
         | $SED "s/^\+ /<li>/1" | $SED "s/$/<\/li>/g" >> ${tmp}/body.tmp
       fi
       next_line=$($SED -n "$(echo "$line_count + 1" | bc)p" $source)
       if [[ ! "$next_line" =~ "^[-*+] " ]] && [[ "$normal_list_flg" == "yes" ]];then
         echo "</ul>" >> ${tmp}/body.tmp
         echo "</div>" >> ${tmp}/body.tmp
         normal_list_flg=""
       fi
     else
       echo "$line" >> ${tmp}/body.tmp
     fi

   # Number list
   elif echo "$line" | grep -qE "^[0-9]+\. "; then
     if [ ! "$extention_flg" -a ! "$code_flg" ];then
       if [ ! "$number_list_flg" ];then
         number_list_flg=yes
         echo "<div class=\"num-list\">" >> ${tmp}/body.tmp
         echo "<ul>" >> ${tmp}/body.tmp
         echo  "$line" | $SED -r "s/^[0-9]+\. /<li>/g" | $SED "s/$/<\/li>/g" >> ${tmp}/body.tmp
       else
         echo  "$line" | $SED -r "s/^[0-9]+\. /<li>/g" | $SED "s/$/<\/li>/g" >> ${tmp}/body.tmp
       fi
       next_line=$($SED -n "$(echo "$line_count + 1" | bc)p" $source)
       if [[ ! "$next_line" =~ ^[0-9]+\. ]] && [[ "$number_list_flg" == "yes" ]];then
         echo "</ul>" >> ${tmp}/body.tmp
         echo "</div>" >> ${tmp}/body.tmp
         number_list_flg=""
       fi
     else
       echo "$line" >>  ${tmp}/body.tmp
     fi

   # code
   elif [[ "$line" == "%code_block%" ]];then 
     if [ ! "$code_flg"  ];then
       echo -n "<pre class=\"code\">" >> ${tmp}/body.tmp 
       code_flg=yes
     else
       echo "</pre>" >> ${tmp}/body.tmp
       code_flg=""
     fi 

   elif [[ "$code_flg" == "yes" ]] && [[ "$tab_4space" == "" ]];then
       echo "$line" | $SED "s/_%%tab_/\\t/g" | $SED "s/_%%space_/ /g" | $SED "s/_%%4space_/    /g" \
       | $SED "s/{%%%}{%%%}{%%%}/:::/g"  >> ${tmp}/body.tmp

   elif [[ "$line" == %%_tab_* || "$line" == _%%4space_* ]];then 
     if [ ! "$code_flg" ];then 
       tab_4space=yes
       code_flg=yes 
       echo -n "<pre class=\"code\">" >> ${tmp}/body.tmp 
       echo "$line" | $SED "s/_%%tab_//g" | $SED "s/_%%4space_//g" | $SED "s/{%%%}{%%%}{%%%}/:::/g" >> ${tmp}/body.tmp
     elif [ "tab_4space" -a "$code_flg" ];then
       echo "$line" | $SED "s/_%%tab_//g" | $SED "s/_%%4space_//g" | $SED "s/{%%%}{%%%}{%%%}/:::/g" >> ${tmp}/body.tmp
     fi

   elif [[ "$line" == "" ]] && [[ "$code_flg" == "yes" ]] && [[ "$tab_4space" == "yes" ]];then
      echo "</pre>" >> ${tmp}/body.tmp
      code_flg=""
      tab_4space=""


   # Extension code
   elif [[ "$line" == {%%%}{%%%}{%%%}* ]];then 
     if [ ! "$extension_code" ];then
       extension_code=yes
       if [[ "$line" == *Warning*  || "$line" == *warning* ]];then
         echo "<pre class=\"warning\"><b>Warning</b>" >> ${tmp}/body.tmp
       else
         echo "<pre class=\"note\"><b>Note</b>" >> ${tmp}/body.tmp
       fi
     else
      echo "</pre>" >> ${tmp}/body.tmp
      extension_code=""
     fi

   elif [[ "$extension_code" == "yes" ]];then
     echo "$line" >> ${tmp}/body.tmp

   #table
   elif [[ "$line" == \|*\|* ]];then
     if [ ! "$table_flg" ];then
       table_flg=yes
       echo "<div class=\"flex-table\">" >> ${tmp}/body.tmp
       echo "<ul>" >> ${tmp}/body.tmp
       echo "<li class=\"flex-table-header\">" >> ${tmp}/body.tmp
       echo "$line" | $SED "s/|/<p>/1" | $SED "s/|/<\/p><p>/g" | $SED "s/<p>$/\n<\/li>/g" >> ${tmp}/body.tmp
     else
       if [[ "$line" == \|--* ]];then
         echo "" > /dev/null
       else
         echo "$line" | $SED "s/|/<li><p>/1" | $SED "s/|/<\/p><p>/g" | $SED "s/<p>$/<\/li>/g" >> ${tmp}/body.tmp
       fi
     fi

   elif [[ "$line" == --* ]] && [[ "$table_flg" == "yes" ]];then
      echo "" > /dev/null

   elif [[ ! "$line" == \|*\|* ]] && [[ "$table_flg" == "yes" ]];then
      echo "</ul>" >> ${tmp}/body.tmp
      echo "</div>" >> ${tmp}/body.tmp
      table_flg=""
  
   # link
   elif [[ "$line" == *\[*\]\(*\)* ]];then
     element_l=$(echo "$line" | $AWK -F "[" '{print $1}')
     tag=$(echo "$line" | $AWK -F "[" '{print $2}' | $SED -r "s/](.*)//g")
     url=$(echo "$line" | $AWK -F "(" '{print $2}' | $SED -r "s/\)(.*)//g")
     element_r=$(echo "$line" | $AWK -F ")" '{print $2}')
     echo "<p>$element_l <a href=\"${url}\">$tag</a> $element_r</p>" >> ${tmp}/body.tmp

   # button 
   elif [[ "$line" == *\[*\]* ]];then
     echo "$line" | $SED "s/\[/<button>/1" | $SED "s/\]/<\/button>/1" >> ${tmp}/body.tmp

   # bold 
   elif [[ "$line" == *\*\**\*\** ]];then
     new_line=$(echo "$line" | $SED "s/\*\*/<b>/1" | $SED "s/\*\*/<\/b>/1")

     while [[ "$new_line" == *\*\** ]]
     do
       new_line=$(echo "$new_line" | $SED "s/\*\*/<b>/1" | $SED "s/\*\*/<\/b>/1")
     done
     echo "$new_line" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" >> ${tmp}/body.tmp

   # italic
   elif [[ "$line" == *\**\** ]];then
     new_line=$(echo "$line" | $SED "s/\*/<em>/1" | $SED "s/\*/<\/em>/1")

     while [[ "$new_line" == *\** ]]
     do
       new_line=$(echo "$new_line" | $SED "s/\*/<em>/1" | $SED "s/\*/<\/em>/1") 
     done
     echo "$new_line" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" >> ${tmp}/body.tmp

   #HN
   elif [[ "$line" == \#\#\#\#\#\#* ]];then
     echo "$line" | $SED "s/###### /######/g" | $SED "s/######/<h6>/1" | $SED "s/$/<\/h6>/g" | $SED "s/######//g" >> ${tmp}/body.tmp

   elif [[ "$line" == \#\#\#\#\#* ]];then
     echo "$line" | $SED "s/##### /#####/g" | $SED "s/#####/<h5>/1" | $SED "s/$/<\/h5>/g" |  $SED "s/######//g" >> ${tmp}/body.tmp

   elif [[ "$line" == \#\#\#\#* ]];then
     echo "$line" | $SED "s/#### /####/g"  | $SED "s/####/<h4>/1" | $SED "s/$/<\/h4>/g" | $SED "s/####//g" >> ${tmp}/body.tmp

   elif [[ "$line" == \#\#\#* ]];then
     echo "$line" | $SED "s/### /###/g" | $SED "s/###/<h3>/1" | $SED "s/$/<\/h3>/g" | $SED "s/###//g" >> ${tmp}/body.tmp

   elif [[ "$line" == \#\#* ]];then
     hashlink=$(echo "$line" | $SHASUM | $AWK '{print $1}')
     echo "$line" | $SED "s/## /##/g" | $SED "s/##/<h2 id=\"${hashlink}\">/1" | $SED "s/$/<\/h2>/g" | $SED "s/## //g" >> ${tmp}/body.tmp
     echo "$line" | $SED "s/## /##/g" | $SED "s/##/<a href=\"#${hashlink}\"><p>/1" | $SED "s/$/<\/p><\/a>/g" | $SED "s/## //g" >> ${tmp}/leftnav.tmp

   elif [[ "$line" == \#* ]];then
     if [ ! "$top_flg" ];then
       top_flg=yes
       echo "$line" | $SED "s/# /#/g" | $SED "s/#/<h1>/1" | $SED "s/$/<\/h1>/g" | $SED "s/# //g" >> ${tmp}/body.tmp
     else
       hashlink=$(echo "$line" | $SHASUM | $AWK '{print $1}')
       echo "$line" | $SED "s/# /#/g" | $SED "s/#/<h1 id=\"${hashlink}\">/1" | $SED "s/$/<\/h1>/g" | $SED "s/# //g" >> ${tmp}/body.tmp
       echo "$line" | $SED "s/# /#/g" | $SED "s/#/<a href=\"#${hashlink}\"><p>/1" | $SED "s/$/<\/p><\/a>/g" | $SED "s/# //g" >> ${tmp}/leftnav.tmp
     fi

   # Add Calendar
   elif [[ "$line" == %%calendar ]];then
     calendar_flg=yes
     echo "<div id=\"my-calendar\"></div>" >> ${tmp}/body.tmp
     echo "%%event_add_btn" >> ${tmp}/body.tmp
     cat <<EOF > ${tmp}/calendar.js.tmp
      document.addEventListener('DOMContentLoaded', function() {
        const calendar = new SimpleCalendar('#my-calendar', {
          initialView: 'month',
          initialDate: new Date(),
          events: [
            // %%events
          ],
          theme: 'default'
        });
        // Listen for events
        calendar.on('eventClick', function(event) {
          console.log('Event clicked:', event);
        });
      });
EOF


   # No tag
   else
     if [ ! "$line" = "" ];then
       echo "$line" | $SED "s/_%%space_/ /g" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" \
      | $SED "s/{%%%}{%%%}{%%%}/:::/g"  >> ${tmp}/body.tmp
     fi
   fi

  ((line_count++))

done  < $source

# handle right header of portal
righth=$($META chk.null:${databox}{$id} | grep righth | $AWK -F ":" '{print $2}')
if [ $righth -eq 1 ];then
  echo "<div class=\"navbar-right-menu\">" > ${tmp}/righth.tmp
  echo "<button class=\"even-btn\">=</button>" >> ${tmp}/righth.tmp
  echo "<nav>" >> ${tmp}/righth.tmp
  echo "<ul>" >> ${tmp}/righth.tmp
  $DATA_SHELL databox:${databox} action:get id:$id key:righth format:none \
  | $SED "s/righth://g" | $SED "s/_%%enter_/\n/g" | $SED "s/Log Out:/Log Out #%%user:/g" \
  > ${tmp}/righth_raw.data

  while read r_line
  do
    tag=$(echo "$r_line" |$AWK -F ":" '{print $1}')
    url=$(echo "$r_line" |cut -f 2- -d ":" | $SED "s/ //g")
    if [ "$tag" = "ExportKey" -a "$url" = "yes" ];then
      export_key=yes
    else
      if [[ "$tag" == *Table ]];then
        echo "<li><a href=\"${url}\"><p style=\"text-transform: capitalize;\">$tag</p></a></li>" >> ${tmp}/righth.tmp
      else
        echo "<li><a href=\"${url}\">$tag</a></li>" >> ${tmp}/righth.tmp
      fi
    fi
  done < ${tmp}/righth_raw.data

  if [ "$export_key" = "yes" ];then
    echo "<li><button class=\"inside-menu-button\" onclick=\"duplicateKey()\">Export access key</button></li>" \
    >> ${tmp}/righth.tmp
  fi
  echo "</nav>" >> ${tmp}/righth.tmp
  echo "</ul>" >> ${tmp}/righth.tmp
  echo "</div>" >> ${tmp}/righth.tmp

  if [ "$export_key" = "yes" ];then
    rand=$($META get.rand)
    cat ${small_shell_path}/web/src/def/common_parts/tmplt_common_menu_button | grep -v "^<li>" \
    | ${SED} "s/%%rand/${rand}/g" | ${SED} "s/%%app/${app}/g" >> ${tmp}/righth.tmp

  fi
else
  echo "<!-- no right header-->" > ${tmp}/righth.tmp
fi

# handle left header of portal page
lefth=$($META chk.null:${databox}{$id} | grep lefth | $AWK -F ":" '{print $2}')
if [ $lefth -eq 1 ];then
  $DATA_SHELL databox:${databox} action:get id:$id key:lefth format:none \
  | $SED "s/lefth://g" | ${SED} "s/_%%enter_/\n/g" > ${tmp}/lefth_raw.data
  while read l_line
  do
    tag=$(echo "$l_line" |$AWK -F ":" '{print $1}')
    url=$(echo "$l_line" |cut -f 2- -d ":" | $SED "s/ //g")
    echo "<h2><a href=\"${url}\">$tag</a></h2>" >> ${tmp}/lefth.tmp
  done < ${tmp}/lefth_raw.data
else
  echo "<!-- no left header-->" > ${tmp}/lefth.tmp
fi

# handle logo
logo_img=$($DATA_SHELL databox:${databox} action:get id:$id key:logo format:none | $SED "s/logo://g")
if [ "$logo_img" ];then
  logo_id=$(echo "$logo_img" | $AWK -F "images/" '{print $2}' | $AWK -F ">" '{print $1}' | $SED "s/\"//g")
  file_type=$($DATA_SHELL databox:images.db id:${logo_id} remote_addr:localhost key:image action:get format:none \
  | $SED "s/image://g" | $AWK -F "#" '{print $1}' | $AWK -F "." '{print $NF}' | $SED "s/ //g")

  $DL databox:images.db id:${logo_id} remote_addr:localhost > %%www/html/images/${logo_id}.${file_type}
  echo "<a href=\"./${app}?%%params\"><img src=\"../images/${logo_id}.${file_type}\" width=\"75%\"></a>" > ${tmp}/logo.tmp
  $SED -e "1i $(cat ${tmp}/logo.tmp)" ${tmp}/leftnav.tmp > ${tmp}/leftnav.tmp.1
  cat ${tmp}/leftnav.tmp.1 > ${tmp}/leftnav.tmp
fi 

# handle footer
footer=$($META chk.null:${databox}{$id} | grep footer | $AWK -F ":" '{print $2}')

if [ $footer -eq 1 ];then
  $DATA_SHELL databox:${databox} action:get id:$id key:footer format:none \
  | $SED "s/footer://g" | ${SED} "s/_%%enter_/\n/g" | $SED "s/^/<p>/g" | $SED "s/$/<\/p>/g" > ${tmp}/footer.tmp
else
  echo "<!-- no footer-->" > ${tmp}/footer.tmp
fi

# update main.html.def
cat %%www/def/${app}_main.html.incmd.def | $SED -r "s/^( *)</</1" \
| $SED "/%%body/r ${tmp}/body.tmp" | $SED "s/%%body//g" \
| $SED "/%%leftnav/r ${tmp}/leftnav.tmp" | $SED "s/%%leftnav//g" \
| $SED "/%%righth/r ${tmp}/righth.tmp" | $SED "s/%%righth//g" \
| $SED "/%%lefth/r ${tmp}/lefth.tmp" | $SED "s/%%lefth//g" \
| $SED "/%%footer/r ${tmp}/footer.tmp" | $SED "s/%%footer//g" \
| $SED "/%%extension_area/r ${tmp}/calendar.js.tmp" | $SED "s/%%extension_area/handle calendar/g" \
| $SED "s/?req=/?%%session\&req=/g"\
> %%www/def/${app}_main.html.def

if [ "$calendar_flg" = "yes" ];then
  cat %%www/def/${app}_main.html.def \
  | $SED "s/<\!-- %%extension-lib //g" | $SED "s/ for simple-calendar -->//g" > %%www/def/.${app}_main.html.def.tmp
  cp %%www/def/.${app}_main.html.def.tmp %%www/def/${app}_main.html.def
  rm -f %%www/def/.${app}_main.html.def.tmp
fi

# update common menu
cat ${tmp}/righth.tmp | grep \<li\> | $SED "s/?req=/?%%session\&req=/g" \
> %%www/def/common_parts/${app}_common_menu

if [ "$export_key" = "yes" ];then
  cat ${small_shell_path}/web/src/def/common_parts/tmplt_common_menu_button | grep -v "^<li>" \
  | ${SED} "s/%%rand/${rand}/g" | ${SED} "s/%%app/${app}/g" \
  >> %%www/def/common_parts/${app}_common_menu
fi

exit 0
