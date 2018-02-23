#! /usr/bin/python
# -*- coding: utf8 -*-
import logging
from elasticsearch import Elasticsearch 
from datetime import date, timedelta, datetime
from iso8601utils import parsers
import codecs
import redis
import time

def message (**kwargs) :
	dict ={
		'wlogon_001': u'Чо за перец? Первый раз такого вижу.',
		'wlogon_002': u'Ну очень давно не виделись. Не отмечался уже много дней',
		'wlogon_003': u'Давно не виделись. Не отмечался уже несколько дней',
		'wlogon_004': u"НЕВЕРНЫЙ СЕТЕВОЙ ЛОГОН валидного юзера.",
		'wlogon_005': u"ПРЕВЫШЕН ПОРОГ. Количество неверных логонов валидного юзера превысило порог за период.",
		'wlogon_006': u"ПРЕВЫШЕН ПОРОГ. Количество неверных сетевых логонов валидных юзеров c одного источника превысило порог за период.",
		'wlogon_007': u"ПРЕВЫШЕН ПОРОГ. Количество неверных сетевых логонов валидных юзеров на один целевой хост превысило порог за период.",
		'wlogon_008': u"НЕВЕРНЫЙ ИНТЕРАКТИВНЫЙ ЛОГОН валидного юзера.",
		'wlogon_009': u"ПРЕВЫШЕН ПОРОГ. Количество неверных интерактивных логонов валидного юзера превысило порог за период.",
		'wlogon_010': u"ПРЕВЫШЕН ПОРОГ. Количество неверных интерактивных логонов валидных юзеров на один целевой хост превысило порог за период.",
		'wlogon_011': u"НЕВЕРНЫЙ СЕТЕВОЙ ЛОГОН НЕИЗВЕСТНОГО юзера.",
		'wlogon_012': u"ПРЕВЫШЕН ПОРОГ. Общее количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров превысило порог за период.",
		'wlogon_013': u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНОГО юзера превысило порог за период.",
		'wlogon_014': u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров c одного источника превысило порог за период.",
		'wlogon_015': u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров на один целевой хост превысило порог за период.",
		'wlogon_016': u"НЕВЕРНЫЙ ИНТЕРАКТИВНЫЙ ЛОГОН НЕИЗВЕСТНОГО юзера.",
		'wlogon_017': u"ПРЕВЫШЕН ПОРОГ. Общее количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНЫХ юзеров превысило порог за период.",
		'wlogon_018': u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНОГО юзера превысило порог за период.",
		'wlogon_019': u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНЫХ юзеров на один целевой хост превысило порог за период.",
		'wlogon_020': u"ПРЕВЫШЕН ПОРОГ. Количество РАЗЛИЧНЫХ ЦЕЛЕВЫХ ХОСТОВ, к которым валидный юзер выполнил СЕТЕВОЙ ЛОГОН, превысило порог за период.",
		'wlogon_021': u"ПРЕВЫШЕН ПОРОГ. Количество РАЗЛИЧНЫХ ЦЕЛЕВЫХ ХОСТОВ, к которым валидные юзеры выполнили СЕТЕВОЙ ЛОГОН с ОДНОГО ИСТОЧНИКА, превысило порог за период."
	}
	for key,value in kwargs.iteritems():
		print key + " : " + value
		if key == 'event_id' :
			print 'event_desc : ' + dict[value]
		

interactive_logon_types = [	u'Интерактивный', u'Снятие блокировки (локально)', u'Новая учетная запись', u'Интерактивный (удаленно)', u'Интерактивный (из кэша)', u'Интерактивный (удаленно, из кэша)', u'Снятие блокировки (из кэша)']
network_logon_types = [u'Сетевой',u'Сетевой (открытый текст)']
# не считаем валидные сетевые логоны на эти хосты
# это касается, контроллеров домена, файловых серверов, серверов Exchange
network_logon_excepted_target_hosts = [] 
# не считаем валидные интерактивные логоны на эти хосты
# это касается серверов служб терминалов
interactive_logon_excepted_target_hosts = [] 

r = redis.StrictRedis(host='localhost', port=6379, db=0)
es = Elasticsearch()
current_watcher_timestamp = datetime.now()
# Запрашиваем у редиса параметр watcher_lastcheck
if r.exists('logon_watcher_lastcheck') :
	logon_watcher_lastcheck = r.get('logon_watcher_lastcheck')
else:
	logon_watcher_lastcheck = current_watcher_timestamp.isoformat()


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
	logon_type = hit['_source']['event_data']['LogonType']
	logon_event_id = hit['_id']
	logon_index = hit['_index']
	
	if r.sismember("known_valid_logons", username):
		last_logon_time = r.get(username+':last_logon_time')
		delta = (parsers.datetime(last_logon_time) - parsers.datetime(current_logon_time)).days
		if delta > 30 :
			message(event_id='wlogon_002', username=username, days=str(delta))
		elif delta > 7 :
			message(event_id='wlogon_003', username=username, days=str(delta))	
	else:
		message(event_id='wlogon_001', username=username)
		r.sadd("known_valid_logons", username)
	r.set(username+':last_logon_time', current_logon_time)
	r.set(username+':last_logon_event', logon_index + ":" + logon_event_id)
	# считаем статистику валидных логонов
	if logon_type in network_logon_types:
		source_ip = hit['_source']['event_data']['IpAddress']
		target_host = hit['_source']['computer_name'].lower()
		if target_host in network_logon_excepted_target_hosts :
			break
		item = username + ":" + source_ip + ":" + target_host + ":" + logon_index + ":" + logon_event_id
		score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
		if r.zadd("valid_logon:network", score, item) == 0 :
			break
		# Группировка по юзерам. user to target
		
		r.zadd("valid_logon:network:per_user:" + username, score, target_host)
		last_hour = score - 3600
		count = r.zcount("valid_logon:network:per_user:" + username, last_hour, score)
		if count in [6,11,101,1001,10001] :
			message(event_id='wlogon_020', username=username, period=u"Последний час", count=str(count))
		last_day = score - 86400
		count = r.zcount("valid_logon:network:per_user:" + username, last_day, score)
		if count in [11,101,1001,10001] :
			message(event_id='wlogon_020', username=username, period=u"Последние сутки", count=str(count))
		last_weak = score - 86400*7
		count = r.zcount("valid_logon:network:per_user:" + username, last_weak, score)
		if count in [101,1001,10001] :
			message(event_id='wlogon_020', username=username, period=u"Последняя неделя", count=str(count))
			
		# Группировка по источникам. source_ip to target
			
		r.zadd("valid_logon:network:source_ip:" + source_ip, score, target_host)
		last_hour = score - 3600
		count = r.zcount("valid_logon:network:source_ip:" + source_ip, last_hour, score)
		if count in [6,11,101,1001,10001] :
			message(event_id='wlogon_021', source_ip=source_ip, period=u"Последний час", count=str(count))
		last_day = score - 86400
		count = r.zcount("valid_logon:network:source_ip:" + source_ip, last_day, score)
		if count in [11,101,1001,10001] :
			message(event_id='wlogon_021', source_ip=source_ip, period=u"Последние сутки", count=str(count))
		last_weak = score - 86400*7
		count = r.zcount("valid_logon:network:source_ip:" + source_ip, last_weak, score)
		if count in [101,1001,10001] :
			message(event_id='wlogon_021', source_ip=source_ip, period=u"Последняя неделя", count=str(count))
			

	
# Поиск новых инвалидных логонов в сети
myquery = {"query": {
	"constant_score":{ 
		 "filter":{
			"bool": 
				{"must":[
							{"range":{"@timestamp":{"gte":logon_watcher_lastcheck, "format":"date_optional_time", "time_zone": "+03:00"}}},
							{"range":{"@timestamp":{"lt":current_watcher_timestamp, "format":"date_optional_time", "time_zone": "+03:00"}}},
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
	logon_type = hit['_source']['event_data']['LogonType']
	logon_event_id = hit['_id']
	logon_index = hit['_index']
	
	if r.sismember("known_valid_logons", username):
		if logon_type in network_logon_types :
			source_ip = hit['_source']['event_data']['IpAddress']
			target_host = hit['_source']['computer_name'].lower()
			item = username + ":" + source_ip + ":" + target_host + ":" + logon_index + ":" + logon_event_id
			score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			if r.zadd("valid_bad_logon:network", score, item) == 0 :
				break
			message(event_id='wlogon_004', username=username, source_ip=source_ip, target_host=target_host)

			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("valid_bad_logon:network:per_user:" + username, score, item)
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:network:per_user:" + username, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_005', username=username, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("valid_bad_logon:network:per_user:" + username, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_005', username=username, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("valid_bad_logon:network:per_user:" + username, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_005', username=username, period=u"Последняя неделя", count=str(count))
			
			# считаем события по IP источника
			r.zadd("valid_bad_logon:network:per_source_ip:" + source_ip, score, item)
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:network:per_source_ip:" + source_ip, last_hour, score)
			if count in [6,11,101,1001,10001]:
				message(event_id='wlogon_006', source_ip=source_ip, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("valid_bad_logon:network:per_source_ip:" + source_ip, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_006', source_ip=source_ip, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("valid_bad_logon:network:per_source_ip:" + source_ip, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_006', source_ip=source_ip, period=u"Последняя неделя", count=str(count))
				
			# считаем события по target_host
			r.zadd("valid_bad_logon:network:per_target_host:" + target_host, score, item)
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:network:per_target_host:" + target_host, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_007', target_host=target_host, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("valid_bad_logon:network:per_target_host:" + target_host, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_007', target_host=target_host, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("valid_bad_logon:network:per_target_host:" + target_host, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_007', target_host=target_host, period=u"Последняя неделя", count=str(count))
		elif logon_type in interactive_logon_types :
			target_host = hit['_source']['computer_name'].lower()
			item = username + ":" + target_host + ":" + logon_index + ":" + logon_event_id
			score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			if r.zadd("valid_bad_logon:interactive", score, item) == 0 :
				break
				
			message(event_id='wlogon_008', username=username, target_host=target_host)

			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("valid_bad_logon:interactive:per_user:" + username, score, item)
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:interactive:per_user:" + username, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_009', username=username, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("valid_bad_logon:interactive:per_user:" + username, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_009', username=username, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("valid_bad_logon:interactive:per_user:" + username, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_009', username=username, period=u"Последняя неделя", count=str(count))
			
			# считаем события по target_host
			r.zadd("valid_bad_logon:interactive:per_target_host:" + target_host, score, item)
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:interactive:per_target_host:" + target_host, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_010', target_host=target_host, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("valid_bad_logon:interactive:per_target_host:" + target_host, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_010', target_host=target_host, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("valid_bad_logon:interactive:per_target_host:" + target_host, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_010', target_host=target_host, period=u"Последняя неделя", count=str(count))
	else:
		if logon_type in network_logon_types :
			source_ip = hit['_source']['event_data']['IpAddress']
			target_host = hit['_source']['computer_name']
			item = username + ":" + source_ip + ":" + target_host + ":" + logon_index + ":" + logon_event_id
			score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			if r.zadd("invalid_bad_logon:network", score, item) == 0 :
				break
			message(event_id='wlogon_011', username=username, source_ip=source_ip, target_host=target_host)

			#считаем общие события по инвалидным юзерам
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:network", last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_012', period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:network", last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_012', period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:network", last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_012', period=u"Последняя неделя", count=str(count))
			
			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("invalid_bad_logon:network:per_user:" + username, score, item)
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:network:per_user:" + username, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_013', username=username, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:network:per_user:" + username, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_013', username=username, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:network:per_user:" + username, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_013', username=username, period=u"Последняя неделя", count=str(count))
			
			# считаем события по IP источника
			r.zadd("invalid_bad_logon:network:per_source_ip:" + source_ip, score, item)
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:network:per_source_ip:" + source_ip, last_hour, score)
			if count in [6,11,101,1001,10001]:
				message(event_id='wlogon_014', source_ip=source_ip, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:network:per_source_ip:" + source_ip, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_014', source_ip=source_ip, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:network:per_source_ip:" + source_ip, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_014', source_ip=source_ip, period=u"Последняя неделя", count=str(count))
				
			# считаем события по target_host
			r.zadd("invalid_bad_logon:network:per_target_host:" + target_host, score, item)
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:network:per_target_host:" + target_host, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_015', target_host=target_host, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:network:per_target_host:" + target_host, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_015', target_host=target_host, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:network:per_target_host:" + target_host, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_015', target_host=target_host, period=u"Последняя неделя", count=str(count))
		elif logon_type in interactive_logon_types :
			target_host = hit['_source']['computer_name']
			item = username + ":" + target_host + ":" + logon_index + ":" + logon_event_id
			score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			if r.zadd("invalid_bad_logon:interactive", score, item) == 0 :
				break
			message(event_id='wlogon_016', username=username, target_host=target_host)

			#считаем общие события по инвалидным юзерам
			last_hour = score - 3600
			count = r.zcount("valid_bad_logon:interactive", last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_017', period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:interactive", last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_017', period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:interactive", last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_017', period=u"Последняя неделя", count=str(count))
				
			item = logon_index + ":" + logon_event_id
			# считаем события по юзеру
			r.zadd("invalid_bad_logon:interactive:per_user:" + username, score, item)
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:interactive:per_user:" + username, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_018', username=username, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:interactive:per_user:" + username, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_018', username=username, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:interactive:per_user:" + username, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_018', username=username, period=u"Последняя неделя", count=str(count))
			
			# считаем события по target_host
			r.zadd("invalid_bad_logon:interactive:per_target_host:" + target_host, score, item)
			last_hour = score - 3600
			count = r.zcount("invalid_bad_logon:interactive:per_target_host:" + target_host, last_hour, score)
			if count in [6,11,101,1001,10001] :
				message(event_id='wlogon_019', target_host=target_host, period=u"Последний час", count=str(count))
			last_day = score - 86400
			count = r.zcount("invalid_bad_logon:interactive:per_target_host:" + target_host, last_day, score)
			if count in [11,101,1001,10001] :
				message(event_id='wlogon_019', target_host=target_host, period=u"Последние сутки", count=str(count))
			last_weak = score - 86400*7
			count = r.zcount("invalid_bad_logon:interactive:per_target_host:" + target_host, last_weak, score)
			if count in [101,1001,10001] :
				message(event_id='wlogon_019', target_host=target_host, period=u"Последняя неделя", count=str(count))
		
r.set('logon_watcher_lastcheck', (current_watcher_timestamp - timedelta(seconds=10)).isoformat())
			
			
			
