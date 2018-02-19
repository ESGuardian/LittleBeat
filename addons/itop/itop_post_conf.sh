#!/bin/bash
tz=$(cat /etc/timezone)
docker exec -it my-itop bash -c "sed -i \"s#'timezone' => 'Europe/Paris'#'timezone' => '$tz'#\"  conf/production/config-itop.php; sed -i \"s/form|basic|external/form|basic|external|url/\" conf/production/config-itop.php;"
docker exec -it my-itop bash -c 'sed -i "s/http:\/\/littlebeat/https:\/\/littlebeat/" conf/production/config-itop.php'
sed -i "s/# ssl/ssl/" /etc/nginx/sites-available/default
service nginx restart

