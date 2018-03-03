#! /usr/bin/python
# -*- coding: utf8 -*-
from datetime import date, timedelta, datetime
from iso8601utils import parsers
import codecs
import time
from IPy import IP

class margin_corrector_wlogon(object):
	def __init__(self, conn_elasticsearch,conn_redis, index):
		self.watcher_index = index
		self.es = conn_elasticsearch
		self.r = conn_redis
		self.counter_types = {
			'wlogon_020':{'counters':[{'entity_field':'username','values':{'hour':6,'day':10,'week':100},'common_sufix':'valid_logon|network|per_user|','comment':'targets per user'}]},
			'wlogon_021':{'counters':[{'entity_field':'source_ip','values':{'hour':6,'day':10,'week':100},'common_sufix':'valid_logon|network|per_source_ip|','comment':'targets per source ip'}]},
			'wlogon_031':{'counters':[{'entity_field':'username','values':{'hour':6,'day':10,'week':100},'common_sufix':'valid_logon|interactive|per_user|','comment':'targets per user interactive'}]},
		}
		self.elastic_query_get_entity = {
			"query":{
				"bool": {
					"must": [
						{"term":{"event_id":"event_id"}},
						{"term":{"period":"period"}},
						{"range":{"@timestamp":{"gte":"now-30d"}}}
					]
				}
			},
			"size":"10000",
			"aggs": {
				"by_entity": {
					"terms": {"field": "entity"},
					"aggs" : {
						"counter_stats" : { 
							"stats" : { "field" :"count" } 
						}
					}
				}
			}
		}


		
		
	def search(self):
		def iter_margin (margin_value, iter_query) :
			iter_query['query']['bool']['must'][3]["range"]["count"]["gt"] = margin_value
			iter_res = self.es.search(index=self.watcher_index + "*", body=iter_query)
			if iter_res['aggregations']['counter_stats']['count'] < 5 :
				return margin_value
			margin_value = int(iter_res['aggregations']['counter_stats']['avg']) + 1 
			return iter_margin (margin_value, iter_query)

		for key, value in self.counter_types.iteritems():
			self.elastic_query_get_entity['query']['bool']['must'][0]['term']['event_id'] = key 
			for counter in value['counters']:			
				self.elastic_query_get_entity['aggs']['by_entity']['terms']['field'] = counter['entity_field']
				for counter_name,counter_default_value in counter['values'].iteritems():
					self.elastic_query_get_entity['query']['bool']['must'][1]['term']['period'] = counter_name
					res = self.es.search(index=self.watcher_index + "*", body=self.elastic_query_get_entity)
					for bucket in res['aggregations']['by_entity']['buckets']:
						redis_key = "wlogon_top_margin|" + counter['common_sufix'] + bucket['key'] + "|" + counter_name
						old_margin = self.r.get(redis_key)
						new_margin = old_margin
						if bucket["counter_stats"]['count'] > 10:							
							new_margin = int(bucket["counter_stats"]['avg']) + 1
							iter_query = {
								"query":{
									"bool": {
										"must": [
											{"term":{"event_id":"wlogon_021"}},
											{"term":{counter['entity_field']:bucket['key']}},
											{"term":{"period":"counter_name"}},
											{"range":{"count":{"gt":new_margin}}},
											{"range":{"@timestamp":{"gte":"now-30d"}}}
										]
									}
								},
								"size":"10000",
								"aggs" : {
									"counter_stats" : { 
									"stats" : { "field" :"count" } }
								}
							}
							new_margin = iter_margin(new_margin, iter_query)
							
							
						if ((old_margin is None) and (new_margin is not None)) or (old_margin != new_margin):
							self.r.set(redis_key, new_margin)
							self.r.expire(redis_key, 3600*24*20)
						
		for item in self.r.scan_iter(match='wlogon_top_margin\|*'):
			if self.r.ttl(item) < 7200 :
				cur_margin = int(self.r.get(item))
				delta = int(cur_margin/10)
				if delta == 0 :
					delta = 1
				cur_margin = cur_margin - delta
				if cur_margin == 0 :
					cur_margin = 1
				self.r.set(item, cur_margin)
				self.r.expire(redis_key, 3600*24*5)
				
		