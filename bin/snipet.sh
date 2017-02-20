#!/bin/bash
#
chown -R elasticsearch:elasticsearch /opt/littlebeat/backups
curl -XPUT 'http://localhost:9200/_snapshot/littlebeat' -d '{
    "type": "fs",
    "settings": {
        "location": "/opt/littlebeat/backups",
        "compress": true
    }
}'


curl -XPUT 'localhost:9200/_snapshot/littlebeat/snapshot_kibana?pretty' -H 'Content-Type: application/json' -d'{
  "indices": ".kibana",
  "ignore_unavailable": true,
  "include_global_state": false
}'


curl -XPOST 'localhost:9200/_snapshot/littlebeat/snapshot_kibana/_restore?pretty' 
