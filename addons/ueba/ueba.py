#! /usr/bin/python
# -*- coding: utf8 -*-
import logging
from elasticsearch import Elasticsearch 
from datetime import date, timedelta, datetime
from iso8601utils import parsers
from ueba_lib.wlogon import wlogon
# from ueba_lib.sysnet import sysnet # ACRC Only
from ueba_lib.margin_corrector import margin_corrector_wlogon
from ueba_lib.garbage_collector import garbage_collector
import codecs
import redis
import time

KIBANA_BASE_URL = 'https://littlebeat'
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
		  "type": "keyword"
		},
		"@version": {
		  "type": "keyword"
		}
	  }
	}
  }
}
elastic_not_connected = True
while elastic_not_connected :
	try:
		es = Elasticsearch()
		if es.ping() :
			elastic_not_connected = False
		else:
			time.sleep(60)
	except: 
		pass
		time.sleep(60)
		
if not es.indices.exists_template(name=WATCHER_INDEX_TEMPLATE_NAME):
	# записываем шаблон индекса
	res=es.indices.put_template(name=WATCHER_INDEX_TEMPLATE_NAME, body=WATCHER_INDEX_TEMPLATE)

r = redis.StrictRedis(host='localhost', port=6379, db=0)
wl = wlogon(es,r,WATCHER_INDEX,KIBANA_BASE_URL)
# sn = sysnet(es,r,WATCHER_INDEX,KIBANA_BASE_URL) # ACRC Only
mc_wl = margin_corrector_wlogon(es,r,WATCHER_INDEX)
gc = garbage_collector(r)
mc_wl_counter = 0
gc_counter = 0

while True :
	wl.search()
	# sn.search() # ACRC Only
	mc_wl_counter += 1
	gc_counter += 1
	if mc_wl_counter > 120 :
		mc_wl.search()
		mc_wl_counter = 0
	if gc_counter > 120*24 :
		gc.collect()
		gc_counter = 0
	time.sleep(30)
