#!/bin/bash
NODE=%%node
echo "$(date "+%Y-%m-%d %H:%M:%S") App shell is started" >> /var/www/log/srvdump.log
chown small-shell:small-shell /var/www/log/srvdump.log
$NODE /var/www/app/index.js >> /var/www/log/srvdump.log 2>&1 
exit 0
