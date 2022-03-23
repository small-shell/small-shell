#!/bin/bash

# load query string param
for param in `echo $@`
do

  if [[ $param == databox:* ]]; then
    databox=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == session:* ]]; then
    session=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == pin:* ]]; then
    pin=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == user_name:* ]]; then
    user_name=`echo $param | awk -F":" '{print $2}'`
  fi

  if [[ $param == page:* ]]; then
    page=`echo $param | awk -F":" '{print $2}'`
  fi

  # filter can be input both query string and post
  if [[ $param == table_command:* ]]; then
    table_command=`echo $param | awk -F":" '{print $2}' | sed "s/{%%space}/ /g"`
  fi

done

# load small-shell path
. ../descriptor/.small_shell_path

# SET BASE_COMMAND
META="sudo -u small-shell ${small_shell_path}/bin/meta"
DATA_SHELL="sudo -u small-shell ${small_shell_path}/bin/DATA_shell session:$session pin:$pin"

if [ "$page" = "" ];then
  page=1
fi

# load post param
if [ -s ../tmp/$session/table_command ];then
  table_command=`cat ../tmp/$session/table_command`
fi

primary_key=`$META get.key:$databox{primary}`
sort_chk_post=`echo $table_command | grep "^sort "`
sort_chk_query_string=`echo $table_command | grep "^sort,"`

if [ "$sort_chk_post" -o "$sort_chk_query_string" ];then
  table_command=`echo $table_command | sed "s/ /,/g"`
  sort_option=`echo $table_command | sed "s/sort,//g" | awk -F "," '{print $1}'`
  sort_col=`echo $table_command  | sed "s/sort,//g" | awk -F "," '{print $2}'`
  if [ ! "$sort_col" ];then
    sort_col=$primary_key
  fi
else
  if [[ $table_command == *{*} ]]; then
    filter_key=`echo $table_command | awk -F "{" '{print $1}'`
    filter_word=`echo $table_command | awk -F "{" '{print $2}' | sed "s/}//g" \
    | sed "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | sed "s/*/{%%%%%%%%%%%%%%%}/g" \
    | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | sed "s/#/{%%%%%%%%%%%%%}/g" \
    | sed "s/|/{%%%%%%%%%%%%}/g" \
    | sed "s/\]/{%%%%%%%%%%%}/g" \
    | sed "s/\[/{%%%%%%%%%%}/g" \
    | sed "s/)/{%%%%%%%%%}/g" \
    | sed "s/(/{%%%%%%%%}/g" \
    | sed "s/_/{%%%%%%%}/g" \
    | sed "s/\//{%%%%%}/g"  \
    | sed "s/,/{%%%%%%}/g"  \
    | sed "s/\&/{%%%%}/g" \
    | sed "s/:/{%%%}/g" \
    | sed "s/　/ /g" | sed "s/ /,/g" \
    | php -r "echo preg_quote(file_get_contents('php://stdin'));"`
    filter_table="$filter_key{$filter_word}"
  else 
    filter_table=`echo $table_command  \
    | sed "s/%/{%%%%%%%%%%%%%%%%}/g"\
    | sed "s/'/{%%%%%%%%%%%%%%%%%}/g" \
    | sed "s/*/{%%%%%%%%%%%%%%%}/g" \
    | sed "s/\\\\$/{%%%%%%%%%%%%%%}/g" \
    | sed "s/#/{%%%%%%%%%%%%%}/g" \
    | sed "s/|/{%%%%%%%%%%%%}/g" \
    | sed "s/\[/{%%%%%%%%%%}/g" \
    | sed "s/)/{%%%%%%%%%}/g" \
    | sed "s/(/{%%%%%%%%}/g" \
    | sed "s/_/{%%%%%%%}/g" \
    | sed "s/\//{%%%%%}/g"  \
    | sed "s/,/{%%%%%%}/g"  \
    | sed "s/\&/{%%%%}/g" \
    | sed "s/:/{%%%}/g" \
    | sed "s/　/ /g" | sed "s/ /,/g" \
    | php -r "echo preg_quote(file_get_contents('php://stdin'));"`
  fi
fi

if [ ! -d ../tmp/$session ];then 
  mkdir ../tmp/$session
fi

# -----------------
#  Preprocedure
# -----------------
if [ "$filter_table" ];then
  line_num=`$DATA_SHELL databox:$databox command:show_all[filter=${filter_table}] format:none | wc -l`

elif [ "$sort_col" ];then
  line_num=`$DATA_SHELL databox:$databox command:show_all[sort=${sort_option},${sort_col}] format:none | wc -l`

else
  line_num=`$META get.num:$databox`

fi

# calc pages
((pages = $line_num / 12))
adjustment=`echo "scale=6;${line_num}/12" | bc | awk -F "." '{print $2}'`
line_start=$page
((line_start = $page * 12 - 11))
((line_end = $line_start + 11))

if [ ! "$adjustment" = "000000" ];then
  ((pages += 1))
fi

# -----------------
# Exec command
# -----------------

# gen %%table contents
if [ "$filter_table" ];then
  $DATA_SHELL databox:$databox command:show_all[line=$line_start-$line_end][filter=${filter_table}] > ../tmp/$session/table &

elif [ "$sort_col" ];then
  $DATA_SHELL databox:$databox \
  command:show_all[line=$line_start-$line_end][sort=${sort_option},${sort_col}] > ../tmp/$session/table &

else
  $DATA_SHELL databox:$databox command:show_all[line=$line_start-$line_end] > ../tmp/$session/table &

fi

# gen %%page_link contents
../bin/page_links.sh $page $pages "$table_command" > ../tmp/$session/page_link &

# gen %%tag contents
$META get.tag:$databox > ../tmp/$session/tags
for tag in `cat ../tmp/$session/tags`
do
 echo "<p><a href=\"./shell.app?%%params&req=table&table_command=$tag\">#$tag&nbsp;</a></p>" >> ../tmp/$session/tag &
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
    >> ../tmp/$session/databox_list
  fi
  ((count +=1 ))
done

# error check
err_chk=`grep "error: there is no databox" ../tmp/$session/table`

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
  sort_command="sort option:$sort_option col:$sort_col"
fi

if [ "$line_num" = 0 ];then
  if [ "$err_chk" = "" -a "$filter_table" = "-" -a ! "$sort_col" ];then
    if [ ! "$permission" = "ro" ];then
      echo "<h4><a href=\"./shell.app?%%params&req=get&id=new\">+ ADD DATA</a></h4>" >> ../tmp/$session/table
    else
      echo "<h4>= NO DATA</h4>" >> ../tmp/$session/table
    fi
  elif [ "$sort_col" ];then
    echo "<h4>sort key or option must be wrong</h4>" >> ../tmp/$session/table
  elif [ "$err_chk" ];then
    echo "<h2>404 databox:$databox not found</h2>" > ../tmp/$session/table 
  else
    echo "<h4>= NO DATA</h4>" >> ../tmp/$session/table
  fi
fi

cat ../descriptor/table.html.def | sed "s/^ *</</g" \
| sed "/%%common_menu/r ../descriptor/common_parts/common_menu_${permission}" \
| sed "/%%common_menu/d"\
| sed "/%%table_menu/r ../descriptor/common_parts/table_menu_${permission}" \
| sed "/%%table_menu/d"\
| sed "/%%footer/r ../descriptor/common_parts/footer" \
| sed "/%%footer/d"\
| sed "/%%databox_list/r ../tmp/$session/databox_list" \
| sed "s/%%databox_list//g"\
| sed "/%%table/r ../tmp/$session/table" \
| sed "s/%%table//g"\
| sed "s/%%databox/$databox/g"\
| sed "/%%page_link/r ../tmp/$session/page_link" \
| sed "s/%%page_link//g"\
| sed "/%%tag/r ../tmp/$session/tag" \
| sed "s/%%tag//g"\
| sed "s/%%user/$user_name/g"\
| sed "s/%%num/$line_num/g"\
| sed "s/%%filter/$filter_table/g"\
| sed "s/%%sort/$sort_command/g"\
| sed "s/%%key/$primary_key/g"\
| sed "s/{%%%%%%%%%%%%%%%%%}/'/g"\
| sed "s/{%%%%%%%%%%%%%%%%}/%/g"\
| sed "s/{%%%%%%%%%%%%%%%}/*/g"\
| sed "s/{%%%%%%%%%%%%%%}/$/g"\
| sed "s/{%%%%%%%%%%%%%}/\#/g"\
| sed "s/{%%%%%%%%%%%%}/|/g"\
| sed "s/{%%%%%%%%%%%}/\]/g"\
| sed "s/{%%%%%%%%%%}/\[/g"\
| sed "s/{%%%%%%%%%}/)/g"\
| sed "s/{%%%%%%%%}/(/g"\
| sed "s/{%%%%%%%}/_/g"\
| sed "s/{%%%%%%}/,/g"\
| sed "s/{%%%%%}/\//g"\
| sed "s/{%%%%}/\&/g"\
| sed "s/{%%%}/:/g"\
| sed "s/%%params/session=$session\&pin=$pin\&databox=$databox/g" 

if [ "$session" ];then
  rm -rf ../tmp/$session
fi

exit 0
