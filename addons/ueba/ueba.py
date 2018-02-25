#! /usr/bin/python
# -*- coding: utf8 -*-
import logging
from elasticsearch import Elasticsearch 
from datetime import date, timedelta, datetime
from iso8601utils import parsers
from ueba_lib.wlogon import wlogon
import codecs
import redis
import time

WATCHER_INDEX = "ueba-"
WATCHER_INDEX_TEMPLATE_NAME = "ueba"
WATCHER_INDEX_TEMPLATE = {
  "order": 1,
  "settings": {
	"index": {
	  "mapping": {
		"total_fields": {
		  "limit": 10000
		}
	  },
	  "number_of_shards": 1,
	  "refresh_interval": "5s"
	}
  },
  "index_patterns": [
	"ueba-*"
  ],
  "mappings": {
	"doc": {
	  "dynamic_templates": [
		{
		  "strings_as_keyword": {
			"mapping": {
			  "ignore_above": 1024,
			  "type": "keyword"
			},
			"match_mapping_type": "string"
		  }
		}
	  ],
	  "properties": {        
		"tags": {
		  "type": "text"
		},
		"@timestamp": {
		  "type": "date"
		},
		"source_ip": {
		  "type": "ip"
		},
		"dest_ip": {
		  "type": "ip"
		},
		"days": {
		  "type": "integer"
		},
		"count": {
		  "type": "integer"
		},
		"severity": {
		  "type": "integer"
		},
		"period": {
		  "type": "keyword"
		},
		"source_url": {
		  "type": "keyword"
		},
		"event_desc": {
		  "type": "text"
		},
		"@version": {
		  "type": "keyword"
		}
	  }
	}
  }
}
es = Elasticsearch()
if not es.indices.exists_template(name=WATCHER_INDEX_TEMPLATE_NAME):
	# записываем шаблон индекса
	res=es.indices.put_template(name=WATCHER_INDEX_TEMPLATE_NAME, body=WATCHER_INDEX_TEMPLATE)
r = redis.StrictRedis(host='localhost', port=6379, db=0)
wl=wlogon(es,r,WATCHER_INDEX)
while True :
	wl.search()
	time.sleep(30)