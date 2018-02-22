#! /usr/bin/python
# -*- coding: utf8 -*-
import logging
from elasticsearch import Elasticsearch 
from datetime import date, timedelta, datetime
from iso8601utils import parsers
import codecs
import redis
import re

def message (output='console',event_id='',**kwargs) :
	dict ={
		'wlogon_001': u'Чо за перец $username? Первый раз такого вижу.',
		'wlogon_002': u'Ну очень давно не виделись. $username не отмечался уже $days дней',
		'wlogon_003': u'Давно не виделись. $username не отмечался уже $days дней',
		'wlogon_004': u"Неверный сетевой логон валидного юзера. Юзер: $username Источник: $source_ip Зарегистрирован агентом $target_host",
		'wlogon_005': u"Количество неверных сетевых логонов валидного юзера за последний час превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_006': u"Количество неверных сетевых логонов валидного юзера за последние сутки превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_007': u"Количество неверных сетевых логонов валидного юзера за последнюю неделю превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_008': u"Количество неверных сетевых логонов c одного источника за последний час превысило порог. IP: $source_ip К-во логонов: $count",
		'wlogon_009': u"Количество неверных сетевых логонов c одного источника за последние сутки превысило порог. IP: $source_ip К-во логонов: $count",
		'wlogon_010': u"Количество неверных сетевых логонов c одного источника за последнюю неделю превысило порог. IP: $source_ip К-во логонов: $count",
		'wlogon_0011': u"Количество неверных сетевых логонов на один целевой хост за последний час превысило порог. Имя целевого хоста: $target_host К-во логонов: $count",
		'wlogon_0012': u"Количество неверных сетевых логонов на один целевой хост за последние сутки превысило порог. Имя целевого хоста: $target_host К-во логонов: $count",
		'wlogon_0013': u"Количество неверных сетевых логонов на один целевой хост за последнюю неделю превысило порог. Имя целевого хоста: $target_host К-во логонов: $count",
		'wlogon_014': u"Неверный интерактивный логон валидного юзера. Юзер: $username Зарегистрирован агентом $target_host",
		'wlogon_015': u"Количество неверных интерактивных логонов валидного юзера за последний час превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_016': u"Количество неверных интерактивных логонов валидного юзера за последние сутки превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_017': u"Количество неверных интерактивных логонов валидного юзера за последнюю неделю превысило порог. Юзер: $username К-во логонов: $count",
		'wlogon_0018': u"Количество неверных интерактивных логонов на один целевой хост за последний час превысило порог. Имя целевого хоста: $target_host К-во логонов: $count",
		'wlogon_0019': u"Количество неверных интерактивных логонов на один целевой хост за последние сутки превысило порог. Имя целевого хоста: $target_host К-во логонов: $count",
		'wlogon_0020': u"Количество неверных интерактивных логонов на один целевой хост за последнюю неделю превысило порог. Имя целевого хоста: $target_host К-во логонов: $count"
	}
	outstring = dict[event_id]
	for key,value in kwargs.iteritems():
		search = u"$" + key
		outstring = outstring.replace(search, value)
		
	if output == 'elastic' :
		print "Вывод в Elasticsearch пока не настроен"
	else:
		print outstring
		
interactive_logon_types = [	'Интерактивный', 'Снятие блокировки (локально)', 'Новая учетная запись', 'Интерактивный (удаленно)', 'Интерактивный (из кэша)', 'Интерактивный (удаленно, из кэша)', 'Снятие блокировки (из кэша)']
network_logon_types = ['Сетевой','Сетевой (открытый текст)']

r = redis.StrictRedis(host='localhost', port=6379, db=0)
es = Elasticsearch()
current_watcher_timestamp = datetime.now()
# Запрашиваем у редиса параметр watcher_lastcheck
if r.exists('logon_watcher_lastcheck') :
	logon_watcher_lastcheck = r.get('logon_watcher_lastcheck')
else:
	logon_watcher_lastcheck = current_watcher_timestamp.isoformat()
r.set('logon_watcher_lastcheck', current_watcher_timestamp.isoformat())

# поиск новых валидных логонов в сети

myquery = {"query": {
	"constant_score":{ 
		 "filter":{
			"bool": 
				{"must":[
							{"range":{"@timestamp":{"gte":logon_watcher_lastcheck, "format":"date_optional_time", "time_zone": "+03:00"}}},
							{"range":{"@timestamp":{"lt":current_watcher_timestamp, "format":"date_optional_time", "time_zone": "+03:00"}}},
							{"term":{"event_id":"4624"}},
							{"term":{"log_name":"Security"}}
						]
				}
			}
		}
	},
	"size":"10000"
}
res = es.search(index='winlogbeat-*',body=myquery)

for hit in res['hits']['hits']:
	username = hit['_source']['event_data']['TargetUserName'].lower()
	current_logon_time = hit['_source']['@timestamp']
	logon_type = hit['_source']['event_data']['LogonType'].lower()
	logon_event_id = hit['_id']
	logon_index = hit['_index']
	
	if r.sismember("known_valid_logons", username):
		last_logon_time = r.get(username+':last_logon_time')
		delta = (parsers.datetime(last_logon_time) - parsers.datetime(current_logon_time)).days
		if delta > 30 :
			message(output='console', event_id='wlogon_002', username=username, days=str(delta))
		elif delta > 7 :
			message(output='console', event_id='wlogon_003', username=username, days=str(delta))	
	else:
		message(output='console', event_id='wlogon_001', username=username)
		r.sadd("known_valid_logons", username)
	r.set(username+':last_logon_time', current_logon_time)
	r.set(username+':last_logon_event', logon_index + ":" + logon_event_id)

	
# Поиск новых инвалидных логонов в сети
myquery = {"query": {
	"constant_score":{ 
		 "filter":{
			"bool": 
				{"must":[
							{"range":{"@timestamp":{"gte":logon_watcher_lastcheck, "format":"date_optional_time", "time_zone": "+03:00"}}},
							{"term":{"event_id":"4625"}},
							{"term":{"log_name":"Security"}}
						]
				}
			}
		}
	},
	"size":"10000"
}
res = es.search(index='winlogbeat-*',body=myquery)

for hit in res['hits']['hits']:
	username = hit['_source']['event_data']['TargetUserName'].lower()
	current_logon_time = hit['_source']['@timestamp']
	logon_type = hit['_source']['event_data']['LogonType'].lower()
	logon_event_id = hit['_id']
	logon_index = hit['_index']
	
	if r.sismember("known_valid_logons", username):
		if logon_type in network_logon_types :
			source_ip = hit['_source']['event_data']['IpAddress']
			target_host = hit['_source']['computer_name']
			message(output='console', event_id='wlogon_004', username=username, source_ip=source_ip, target_host=target_host)
			score = parsers.datetime(current_logon_time).timestamp()
			item = "network:" + username + ":" + source_ip + ":" + target_host + ":" + logon_index + ":" + logon_event_id 
			r.zadd("valid_bad_logon", item, score)
			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("valid_bad_logon:network:" + username, item, score)
			last_hour = score - 3600
			count = zcount("valid_bad_logon:network:" + username, last_hour, score)
			if count > 5 :
				message(output='console', event_id='wlogon_005', username=username, count=count)
			last_day = score - 86400
			count = zcount("valid_bad_logon:network:" + username, last_day, score)
			if count > 10 :
				message(output='console', event_id='wlogon_006', username=username, count=count)
			last_weak = score - 86400*7
			count = zcount("valid_bad_logon:network:" + username, last_weak, score)
			if count > 100 :
				message(output='console', event_id='wlogon_007', username=username, count=count)
			
			# считаем события по IP источника
			r.zadd("valid_bad_logon:network:" + source_ip, item, score)
			last_hour = score - 3600
			count = zcount("valid_bad_logon:network:" + source_ip, last_hour, score)
			if count > 5 :
				message(output='console', event_id='wlogon_008', source_ip=source_ip, count=count)
			last_day = score - 86400
			count = zcount("valid_bad_logon:network:" + source_ip, last_day, score)
			if count > 10 :
				message(output='console', event_id='wlogon_009', source_ip=source_ip, count=count)
			last_weak = score - 86400*7
			count = zcount("valid_bad_logon:network:" + source_ip, last_weak, score)
			if count > 100 :
				message(output='console', event_id='wlogon_010', source_ip=source_ip, count=count)
				
			# считаем события по target_host
			r.zadd("valid_bad_logon:network:" + target_host, item, score)
			last_hour = score - 3600
			count = zcount("valid_bad_logon:network:" + target_host, last_hour, score)
			if count > 5 :
				message(output='console', event_id='wlogon_011', target_host=target_host, count=count)
			last_day = score - 86400
			count = zcount("valid_bad_logon:network:" + target_host, last_day, score)
			if count > 10 :
				message(output='console', event_id='wlogon_012', target_host=target_host, count=count)
			last_weak = score - 86400*7
			count = zcount("valid_bad_logon:network:" + target_host, last_weak, score)
			if count > 100 :
				message(output='console', event_id='wlogon_013', target_host=target_host, count=count)
		elif logon_type in interactive_logon_types :
			target_host = hit['_source']['computer_name']
			message(output='console', event_id='wlogon_0014', username=username, target_host=target_host)
			score = parsers.datetime(current_logon_time).timestamp()
			item = "interactive:" + username + ":" + target_host + ":" + logon_index + ":" + logon_event_id 
			r.zadd("valid_bad_logon", item, score)
			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("valid_bad_logon:interactive:" + username, item, score)
			last_hour = score - 3600
			count = zcount("valid_bad_logon:interactive:" + username, last_hour, score)
			if count > 5 :
				message(output='console', event_id='wlogon_0015', username=username, count=count)
			last_day = score - 86400
			count = zcount("valid_bad_logon:interactive:" + username, last_day, score)
			if count > 10 :
				message(output='console', event_id='wlogon_0016', username=username, count=count)
			last_weak = score - 86400*7
			count = zcount("valid_bad_logon:interactive:" + username, last_weak, score)
			if count > 100 :
				message(output='console', event_id='wlogon_0017', username=username, count=count)
			
			# считаем события по target_host
			r.zadd("valid_bad_logon:interactive:" + target_host, item, score)
			last_hour = score - 3600
			count = zcount("valid_bad_logon:interactive:" + target_host, last_hour, score)
			if count > 5 :
				message(output='console', event_id='wlogon_018', target_host=target_host, count=count)
			last_day = score - 86400
			count = zcount("valid_bad_logon:interactive:" + target_host, last_day, score)
			if count > 10 :
				message(output='console', event_id='wlogon_019', target_host=target_host, count=count)
			last_weak = score - 86400*7
			count = zcount("valid_bad_logon:interactive:" + target_host, last_weak, score)
			if count > 100 :
				message(output='console', event_id='wlogon_020', target_host=target_host, count=count)
			
				
				
			
			
			
