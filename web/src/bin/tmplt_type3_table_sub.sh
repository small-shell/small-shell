#!/bin/bash

# Target databox and keys
databox=%%databox
keys=all

# define default num of line per page
num_of_line_per_page=12

# load small-shell conf
. %%www/descriptor/.small_shell_conf

# load query string param
for param in `echo $@`
do

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
META="${small_shell_path}/bin/meta"
DATA_SHELL="${small_shell_path}/bin/DATA_shell session:$session pin:$pin app:%%parent_app"

if [ "$page" = "" ];then
  page=1
fi

# set placeholder 
placeholder="Type any filter words or you can sort column by sort command"

# load post param
if [ -s %%www/tmp/$session/table_command ];then
  table_command=`cat %%www/tmp/$session/table_command`
fi

org_table_command=$table_command
default_key_label=`$META get.label:$databox{all} | $SED "s/#ID,//g" | $AWK -F "," '{print $1}' | $SED "s/ /{%%space}/g"`
sort_chk=`echo $table_command | grep -e "^sort " -e "^sort,"`
num_of_line_chk=`echo $table_command | grep -ie "^#line:" -e " #line:"`

if [ "$num_of_line_chk" ];then
  num_of_line_per_page=`echo $table_command | awk -F ":" '{print $2}'`
  placeholder="Executed $table_command. if you want to clear the table, please click -CLR"
  table_command=`echo $table_command | $SED -r "s/ #(.*):(.*)//g" | $SED -r "s/^#(.*):(.*)//g"`
fi

if [ "$sort_chk" ];then
  table_command=`echo $table_command | $SED "s/ /,/g"`
  sort_option=`echo $table_command | cut -f 2 -d ","`
  sort_label=`echo $table_command  | cut -f 3- -d "," | $SED "s/,/{%%space}/g" \
  | $SED "s/#reverse{%%space}sort{%%space}with{%%space}numetric{%%space}sort//g" \
  | $SED "s/#nature{%%space}sort//g" | $SED "s/#numetric{%%space}sort//g" | $SED "s/#reverse{%%space}sort//g" \
  | $SED "s/{%%space}$//g"`


  if [ "$sort_label" ];then
    sort_key=`$META get.key:$databox{$sort_label}`
    if [ ! "$sort_key" ];then
      sort_label="Failed to search ${sort_label}"
      sort_key=`$META get.key:$databox{$default_key_label}`
    fi
  else
    sort_label=" - "
    sort_key=`$META get.key:$databox{$default_key_label}`
  fi

  placeholder="Executed ${org_table_command}, you can clear the table by clicking -CLR"

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

    key_chk=`$META get.key:$databox{all} | grep "$filter_key"`
    if [ ! "$key_chk" ];then
      org_filter_key=$filter_key
      filter_label=`echo "$filter_key" | $SED "s/ /{%%space}/g" | $SED "s/{%%space}$//g"`
      filter_key=`$META get.key:$databox{$filter_label}`
    fi

    if [ "$filter_key" ];then
      filter_table="$filter_key{$filter_word}"
      placeholder="Executed $table_command. if you want to clear the table, please click -CLR"
    else
      filter_table="$filter_word"
      placeholder="There is no $org_filter_key key, filtered by $filter_word with all column"
    fi

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

    if [ "$filter_table" ];then
      placeholder="Filtered by $table_command. you can clear the table by clicking -CLR"
    fi

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
  line_num=`$DATA_SHELL databox:$databox command:show_all[filter=${filter_table}][keys=$keys] format:none | wc -l | tr -d " "`

elif [ "$sort_key" ];then
  line_num=`$DATA_SHELL databox:$databox command:show_all[sort=${sort_option},${sort_key}] format:none | wc -l | tr -d " "`

else
  line_num=`$META get.num:$databox`

fi

# calc pages
((pages = $line_num / $num_of_line_per_page))
adjustment=`echo "scale=6;${line_num}/${num_of_line_per_page}" | $BC | $AWK -F "." '{print $2}'`
((line_start = $page * ${num_of_line_per_page} - `expr ${num_of_line_per_page} - 1`))
((line_end = $line_start + `expr ${num_of_line_per_page} - 1`))

if [ ! "$adjustment" = "000000" ];then
  ((pages += 1))
fi

#-----------------------
# gen %%table contents
#-----------------------
if [ "$filter_table" ];then
  $DATA_SHELL databox:$databox \
  command:show_all[line=$line_start-$line_end][keys=$keys][filter=${filter_table}] > %%www/tmp/$session/table &

elif [ "$sort_key" ];then
  $DATA_SHELL databox:$databox \
  command:show_all[line=$line_start-$line_end][keys=$keys][sort=${sort_option},${sort_key}] > %%www/tmp/$session/table &
else
  $DATA_SHELL databox:$databox command:show_all[line=$line_start-$line_end][keys=$keys] > %%www/tmp/$session/table &
fi

# gen %%tag contents
$META get.tag:%%app{$databox} > %%www/tmp/$session/tags
for tag in `cat %%www/tmp/$session/tags`
do
 echo "<p><a href=\"./%%parent_app?%%params&req=table&table_command=$tag\">#$tag&nbsp;</a></p>" > %%www/tmp/$session/tag &
done

# load permission
if [ ! "$user_name" = "guest" ];then
  permission=`$META get.attr:%%parent_app/$user_name{permission}`
else
  permission="ro"
  # change displayed name
  user_name=there
fi

# gen %%page_link contents
%%www/bin/%%app_page_links.sh $page $pages "$table_command" $num_of_line_per_page > %%www/tmp/$session/page_link &
wait

# error check
err_chk=`grep "^error: " %%www/tmp/$session/table`

if [ "$err_chk" ];then
  echo "<h2>Oops something must be wrong, please check %%app_table.sh, error message is $err_chk</h2>"

  if [ "$session" ];then
    rm -rf %%www/tmp/$session
  fi
  exit 1
fi

# -----------------
# render HTML
# -----------------
view=%%app_table.html.def
wait

if [ ! "$filter_table" ];then
  filter_table="-"
fi

if [ ! "$sort_key" ];then
  sort_command="-"
else
  sort_command="sort option:$sort_option col:$sort_label"
fi

if [ "$line_num" = 0 ];then
  if [ "$err_chk" = "" -a "$filter_table" = "-" -a ! "$sort_key" ];then
    echo "<h4>= NO DATA</h4>" >> %%www/tmp/$session/table
  elif [ "$sort_key" ];then
    echo "<h4>= SORT OPTION FAILURE</h4>" >> %%www/tmp/$session/table
  else
    echo "<h4>= NO DATA</h4>" >> %%www/tmp/$session/table
  fi
fi

# overwritten by clustering logic
if [ "$replica_hosts" ];then
  cat %%www/tmp/$session/table | $SED "s#./%%parent_app#${cluster_base_url}%%parent_app#g" > %%www/tmp/$session/table.base_url
  table=%%www/tmp/$session/table.base_url
else
  table=%%www/tmp/$session/table
fi

cat %%www/descriptor/$view | $SED -r "s/^( *)</</1" \
| $SED "/%%common_menu/r %%www/descriptor/common_parts/%%parent_app_common_menu" \
| $SED "/%%common_menu/d"\
| $SED "/%%table_menu/r %%www/descriptor/common_parts/%%app_table_menu_${permission}" \
| $SED "/%%table_menu/d"\
| $SED "/%%table/r $table" \
| $SED "s/%%table//g"\
| $SED "/%%page_link/r %%www/tmp/$session/page_link" \
| $SED "s/%%page_link//g"\
| $SED "/%%tag/r %%www/tmp/$session/tag" \
| $SED "s/%%tag//g"\
| $SED "s/%%placeholder/$placeholder/g"\
| $SED "s/%%user/$user_name/g"\
| $SED "s/%%num/$line_num/g"\
| $SED "s/%%filter/$filter_table/g"\
| $SED "s/%%sort/$sort_command/g"\
| $SED "s/%%key/$default_key_label/g"\
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
| $SED "s/.\/base?/.\/%%parent_app?/g"\
| $SED "s/%%session/session=$session\&pin=$pin/g" \
| $SED "s/%%params/subapp=%%app\&session=$session\&pin=$pin\&databox=$databox/g"


if [ "$session" ];then
  rm -rf %%www/tmp/$session
fi

exit 0
