#!/bin/bash

# define default num of line per page
num_of_line_per_page=12

# load small-shell conf
. %%www/descriptor/.small_shell_conf

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == page:* ]]; then
    page=`echo $param | $AWK -F":" '{print $2}'`
  fi

  if [[ $param == line:* ]]; then
    line=`echo $param | $AWK -F":" '{print $2}'`
    if [ "$line" ];then
      num_of_line_per_page=$line
    fi
  fi

  # filter can be input both query string and post
  if [[ $param == table_command:* ]]; then
    table_command=`echo $param | $AWK -F":" '{print $2}' | $SED "s/{%%space}/ /g"`
  fi

done

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ "$page" = "" ];then
  page=1
fi

# load post param
if [ -s %%www/tmp/$session/table_command ];then
  table_command=`cat %%www/tmp/$session/table_command`
fi

primary_key_label=`$META get.label:$databox{primary}`
sort_chk=`echo $table_command | grep -e "^sort " -e "^sort,"`
num_of_line_chk=`echo $table_command | grep -ie "^#line:" -e " #line:"`

if [ "$num_of_line_chk" ];then
  num_of_line_per_page=`echo $table_command | awk -F ":" '{print $2}'`
  table_command=`echo $table_command | $SED -r "s/ #(.*):(.*)//g" | $SED -r "s/^#(.*):(.*)//g"` 
fi

if [ "$sort_chk" ];then
  table_command=`echo $table_command | $SED "s/ /,/g"`
  sort_option=`echo $table_command | $SED "s/sort,//g" | cut -f 1 -d ","`
  sort_label=`echo $table_command  | $SED "s/sort,//g" | cut -f 2- -d "," | $SED "s/,/{%%space}/g"`
  sort_col=`$META get.key:$databox{$sort_label}`

  if [ ! "$sort_col" ];then
    sort_label=" - "
    sort_col=`$META get.key:$databox{$primary_key_label}`
  fi
else
  if [[ $table_command == *{*} ]]; then
    filter_key=`echo $table_command | $AWK -F "{" '{print $1}'`
    filter_word=`echo $table_command | $AWK -F "{" '{print $2}' | $SED "s/}//g" \
    | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | $SED "s/*/{%%%%%%%%%%%%%%%}/g" \
    | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | $SED "s/#/{%%%%%%%%%%%%%}/g" \
    | $SED "s/|/{%%%%%%%%%%%%}/g" \
    | $SED "s/\]/{%%%%%%%%%%%}/g" \
    | $SED "s/\[/{%%%%%%%%%%}/g" \
    | $SED "s/)/{%%%%%%%%%}/g" \
    | $SED "s/(/{%%%%%%%%}/g" \
    | $SED "s/_/{%%%%%%%}/g" \
    | $SED "s/\//{%%%%%}/g"  \
    | $SED "s/,/{%%%%%%}/g"  \
    | $SED "s/\&/{%%%%}/g" \
    | $SED "s/:/{%%%}/g" \
    | $SED "s/　/ /g" | $SED "s/ /,/g" \
    | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));"`
    filter_table="$filter_key{$filter_word}"
  else 
    filter_table=`echo $table_command  \
    | $SED "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | $SED "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | $SED "s/*/{%%%%%%%%%%%%%%%}/g" \
    | $SED "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | $SED "s/#/{%%%%%%%%%%%%%}/g" \
    | $SED "s/|/{%%%%%%%%%%%%}/g" \
    | $SED "s/\[/{%%%%%%%%%%}/g" \
    | $SED "s/)/{%%%%%%%%%}/g" \
    | $SED "s/(/{%%%%%%%%}/g" \
    | $SED "s/_/{%%%%%%%}/g" \
    | $SED "s/\//{%%%%%}/g"  \
    | $SED "s/,/{%%%%%%}/g"  \
    | $SED "s/\&/{%%%%}/g" \
    | $SED "s/:/{%%%}/g" \
    | $SED "s/　/ /g" | $SED "s/ /,/g" \
    | $PHP -r "echo preg_quote(file_get_contents('php://stdin'));"`
  fi
fi

if [ ! -d %%www/tmp/$session ];then 
  mkdir %%www/tmp/$session
fi

if [ $num_of_line_per_page -lt 2 ];then
  num_of_line_per_page=12
fi

# -----------------
#  Preprocedure
# -----------------
if [ "$filter_table" ];then
  line_num=`$DATA_SHELL databox:$databox command:show_all[filter=${filter_table}] format:none | wc -l | tr -d " "`

elif [ "$sort_col" ];then
  line_num=`$DATA_SHELL databox:$databox command:show_all[sort=${sort_option},${sort_col}] format:none | wc -l | tr -d " "`

else
  line_num=`$META get.num:$databox`

fi

# calc pages
((pages = $line_num / $num_of_line_per_page))
adjustment=`echo "scale=6;${line_num}/${num_of_line_per_page}" | bc | $AWK -F "." '{print $2}'`
((line_start = $page * ${num_of_line_per_page} - `expr ${num_of_line_per_page} - 1`))
((line_end = $line_start + `expr ${num_of_line_per_page} - 1`))

if [ ! "$adjustment" = "000000" ];then
  ((pages += 1))
fi

# -----------------
# Exec command
# -----------------

# gen %%table contents
if [ "$filter_table" ];then
  $DATA_SHELL databox:$databox command:show_all[line=$line_start-$line_end][filter=${filter_table}] > %%www/tmp/$session/table &

elif [ "$sort_col" ];then
  $DATA_SHELL databox:$databox \
  command:show_all[line=$line_start-$line_end][sort=${sort_option},${sort_col}] > %%www/tmp/$session/table &

else
  $DATA_SHELL databox:$databox command:show_all[line=$line_start-$line_end] > %%www/tmp/$session/table &

fi

# gen %%page_link contents
%%www/bin/page_links.sh $page $pages "$table_command" $num_of_line_per_page > %%www/tmp/$session/page_link &

# gen %%tag contents
$META get.tag:$databox > %%www/tmp/$session/tags
for tag in `cat %%www/tmp/$session/tags`
do
 echo "<p><a href=\"./shell.app?%%params&req=table&table_command=$tag\">#$tag&nbsp;</a></p>" >> %%www/tmp/$session/tag &
done 


# load permission
permission=`$META get.attr:$user_name{permission}`

# gen databox list for left menu
db_list="$databox `$META get.databox`"
count=0
for db in $db_list
do
  if [ ! "$databox" = "$db" -o $count -eq 0 ];then
    echo "<option value=\"./shell.app?session=$session&pin=$pin&databox=$db&req=table\">DataBox:$db</option>"\
    >> %%www/tmp/$session/databox_list
  fi
  ((count +=1 ))
done

# error check
err_chk=`grep "error: there is no databox" %%www/tmp/$session/table`

# -----------------
# render HTML
# -----------------
wait

if [ ! "$filter_table" ];then
  filter_table="-"
fi

if [ ! "$sort_col" ];then
  sort_command="ordered by latest update"
else
  sort_command="sort option:$sort_option col:$sort_label"
fi

if [ "$line_num" = 0 ];then
  if [ "$err_chk" = "" -a "$filter_table" = "-" -a ! "$sort_col" ];then
    if [ ! "$permission" = "ro" ];then
      echo "<h4><a href=\"./shell.app?%%params&req=get&id=new\">+ ADD DATA</a></h4>" >> %%www/tmp/$session/table
    else
      echo "<h4>= NO DATA</h4>" >> %%www/tmp/$session/table
    fi
  elif [ "$sort_col" ];then
    echo "<h4>sort key or option must be wrong</h4>" >> %%www/tmp/$session/table
  elif [ "$err_chk" ];then
    echo "<h2>404 databox:$databox not found</h2>" > %%www/tmp/$session/table 
  else
    echo "<h4>= NO DATA</h4>" >> %%www/tmp/$session/table
  fi
fi

cat %%www/descriptor/table.html.def | $SED -r "s/^( *)</</1" \
| $SED "/%%common_menu/r %%www/descriptor/common_parts/common_menu_${permission}" \
| $SED "/%%common_menu/d"\
| $SED "/%%table_menu/r %%www/descriptor/common_parts/table_menu_${permission}" \
| $SED "/%%table_menu/d"\
| $SED "/%%footer/r %%www/descriptor/common_parts/footer" \
| $SED "/%%footer/d"\
| $SED "/%%databox_list/r %%www/tmp/$session/databox_list" \
| $SED "s/%%databox_list//g"\
| $SED "/%%table/r %%www/tmp/$session/table" \
| $SED "s/%%table//g"\
| $SED "s/%%databox/$databox/g"\
| $SED "/%%page_link/r %%www/tmp/$session/page_link" \
| $SED "s/%%page_link//g"\
| $SED "/%%tag/r %%www/tmp/$session/tag" \
| $SED "s/%%tag//g"\
| $SED "s/%%user/$user_name/g"\
| $SED "s/%%num/$line_num/g"\
| $SED "s/%%filter/$filter_table/g"\
| $SED "s/%%sort/$sort_command/g"\
| $SED "s/%%key/$primary_key_label/g"\
| $SED "s/{%%%%%%%%%%%%%%%%%}/'/g"\
| $SED "s/{%%%%%%%%%%%%%%%%}/%/g"\
| $SED "s/{%%%%%%%%%%%%%%%}/*/g"\
| $SED "s/{%%%%%%%%%%%%%%}/$/g"\
| $SED "s/{%%%%%%%%%%%%%}/\#/g"\
| $SED "s/{%%%%%%%%%%%%}/|/g"\
| $SED "s/{%%%%%%%%%%%}/\]/g"\
| $SED "s/{%%%%%%%%%%}/\[/g"\
| $SED "s/{%%%%%%%%%}/)/g"\
| $SED "s/{%%%%%%%%}/(/g"\
| $SED "s/{%%%%%%%}/_/g"\
| $SED "s/{%%%%%%}/,/g"\
| $SED "s/{%%%%%}/\//g"\
| $SED "s/{%%%%}/\&/g"\
| $SED "s/{%%%}/:/g"\
| $SED "s/{%%space}/ /g"\
| $SED "s/%%params/session=$session\&pin=$pin\&databox=$databox/g" 

if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
