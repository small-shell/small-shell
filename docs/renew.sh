#!/bin/bash

for target in $(ls | grep -v renew.sh | grep -v chk.sh)
do
  while IFS= read -r line
  do
    if [[ "`echo $line | grep \/`"  ]]; then
     #1. /$変数名で始まるものをsed
     #2. $変数名/で終わる対象をsed
     #3. $変数名\で終わる対象をsed (実際には変数名\&としてparamsを展開しているところに適用)
     #3. $変数名#で終わる対象をsed (実際には変数名\&としてparamsを展開しているところに適用)
     #4. 一個目の`を$(にして二個目の`を)にする
     echo "$line" | sed -E 's/\/\$([a-zA-Z_][a-zA-Z0-9_]*)/\/${\1}/g' | sed -E 's/\$([a-zA-Z_][a-zA-Z0-9_]*)\//${\1}\//g' \
     | sed -E 's/\$([a-zA-Z_][a-zA-Z0-9_]*)\\/\${\1}\\/g' | sed -E 's/\$([a-zA-Z_][a-zA-Z0-9_]*)#/\${\1}#/g' >> ${target}.new
    else
      echo "$line" >> ${target}.new
    fi
  done < $target
done

