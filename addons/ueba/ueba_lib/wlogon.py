#! /usr/bin/python
# -*- coding: utf8 -*-
from datetime import date, timedelta, datetime
from iso8601utils import parsers
import codecs
import time
from IPy import IP

class wlogon(object):
	def __init__(self, conn_elasticsearch,conn_redis, index, kibana_url):
		self.kibana_base_url = kibana_url
		self.watcher_index = index
		self.interactive_logon_types = [2,7,9,10,11,12,13]
		self.network_logon_types = [3,8]
		# не считаем валидные сетевые логоны на эти хосты
		# это касается, контроллеров домена, файловых серверов, серверов Exchange
		self.network_logon_excepted_target_hosts = [] 
		# не считаем валидные интерактивные логоны на эти хосты
		# это касается серверов служб терминалов
		self.interactive_logon_excepted_target_hosts = [] 
		self.es = conn_elasticsearch
		self.r = conn_redis
		self.log_type = 'wlogon'
		self.events = {
			'wlogon_001': [1,u'НОВЫЙ ЮЗЕР. Пользователь с таким именем раньше не отмечался в системе'],
			'wlogon_002': [1,u'ОЧЕНЬ ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР. Пользователь с таким именем не появлялся более 30 дней'],
			'wlogon_003': [1,u'ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР. Пользователь с таким именем не появлялся больше недели'],
			'wlogon_004': [3,u"НЕВЕРНЫЙ СЕТЕВОЙ ЛОГОН валидного юзера."],
			'wlogon_005': [5,u"ПРЕВЫШЕН ПОРОГ. Количество неверных сетевых логонов валидного юзера превысило порог за период."],
			'wlogon_006': [8,u"ПРЕВЫШЕН ПОРОГ. Количество неверных сетевых логонов валидных юзеров c одного источника превысило порог за период."],
			'wlogon_007': [8,u"ПРЕВЫШЕН ПОРОГ. Количество неверных сетевых логонов валидных юзеров на один целевой хост превысило порог за период."],
			'wlogon_008': [3,u"НЕВЕРНЫЙ ИНТЕРАКТИВНЫЙ ЛОГОН валидного юзера."],
			'wlogon_009': [8,u"ПРЕВЫШЕН ПОРОГ. Количество неверных интерактивных логонов валидного юзера превысило порог за период."],
			'wlogon_010': [8,u"ПРЕВЫШЕН ПОРОГ. Количество неверных интерактивных логонов валидных юзеров на один целевой хост превысило порог за период."],
			'wlogon_011': [9,u"НЕВЕРНЫЙ СЕТЕВОЙ ЛОГОН НЕИЗВЕСТНОГО юзера."],
			'wlogon_012': [10,u"ПРЕВЫШЕН ПОРОГ. Общее количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров превысило порог за период."],
			'wlogon_013': [10,u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНОГО юзера превысило порог за период."],
			'wlogon_014': [10,u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров c одного источника превысило порог за период."],
			'wlogon_015': [10,u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ сетевых логонов НЕИЗВЕСТНЫХ юзеров на один целевой хост превысило порог за период."],
			'wlogon_016': [5,u"НЕВЕРНЫЙ ИНТЕРАКТИВНЫЙ ЛОГОН НЕИЗВЕСТНОГО юзера."],
			'wlogon_017': [8,u"ПРЕВЫШЕН ПОРОГ. Общее количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНЫХ юзеров превысило порог за период."],
			'wlogon_018': [10,u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНОГО юзера превысило порог за период."],
			'wlogon_019': [10,u"ПРЕВЫШЕН ПОРОГ. Количество НЕВЕРНЫХ интерактивных логонов НЕИЗВЕСТНЫХ юзеров на один целевой хост превысило порог за период."],
			'wlogon_020': [8,u"ПРЕВЫШЕН ПОРОГ. Количество РАЗЛИЧНЫХ ЦЕЛЕВЫХ ХОСТОВ, к которым валидный юзер выполнил СЕТЕВОЙ ЛОГОН, превысило порог за период."],
			'wlogon_021': [10,u"ПРЕВЫШЕН ПОРОГ. Количество РАЗЛИЧНЫХ ЦЕЛЕВЫХ ХОСТОВ, к которым валидные юзеры выполнили СЕТЕВОЙ ЛОГОН с ОДНОГО ИСТОЧНИКА, превысило порог за период."],
			'wlogon_022': [8,u"НОВЫЙ АДРЕС ИСТОЧНИКА при сетевом логоне на целевой хост."],
			'wlogon_023': [3,u"ОЧЕНЬ ДАВНО НЕ ВСТРЕЧАЛСЯ АДРЕС ИСТОЧНИКА при сетевом логоне на целевой хост."],
			'wlogon_024': [3,u"ДАВНО НЕ ВСТРЕЧАЛСЯ АДРЕС ИСТОЧНИКА при сетевом логоне на целевой хост."],
			'wlogon_025': [5,u"НОВЫЙ ЮЗЕР при сетевом логоне на целевой хост."],
			'wlogon_026': [3,u"ОЧЕНЬ ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР при сетевом логоне на целевой хост."],
			'wlogon_027': [3,u"ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР при сетевом логоне на целевой хост."],
			'wlogon_028': [5,u"НОВАЯ ПАРА ЮЗЕР:IP при сетевом логоне на целевой хост."],
			'wlogon_029': [3,u"ОЧЕНЬ ДАВНО НЕ ВСТРЕЧАЛАСЬ ПАРА ЮЗЕР:IP при сетевом логоне на целевой хост."],
			'wlogon_030': [3,u"ДАВНО НЕ ВСТРЕЧАЛАСЬ ПАРА ЮЗЕР:IP при сетевом логоне на целевой хост."],
			'wlogon_031': [8,u"ПРЕВЫШЕН ПОРОГ. Количество РАЗЛИЧНЫХ ЦЕЛЕВЫХ ХОСТОВ, к которым валидный юзер выполнил ИНТЕРАКТИВНЫЙ ЛОГОН, превысило порог за период."],
			'wlogon_032': [3,u"НОВЫЙ ЮЗЕР при интерактивном логоне на целевой хост."],
			'wlogon_033': [1,u"ОЧЕНЬ ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР при интерактивном логоне на целевой хост."],
			'wlogon_034': [1,u"ДАВНО НЕ ВСТРЕЧАЛСЯ ЮЗЕР при интерактивном логоне на целевой хост."],
		}
		self.limits = {
			'wlogon_005': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_006': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_007': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_009': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_010': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_012': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_013': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_014': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_015': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_017': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_018': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_019': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_020': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_021': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			'wlogon_031': {'hour':[5,3600], 'day':[10,86400], 'week':[100,604800]},
			
		}
		self.norepeat_time = 600
		
		

	def message (self, source_doc) :
		doc = source_doc.copy()
		if ('source_index' in doc.keys()) and ('source_id' in doc.keys()) :
			doc['source_url'] = self.kibana_base_url + '/app/kibana#/doc/winlogbeat-*/' + doc['source_index'] + '/doc?id=' + doc['source_id']
			doc.pop('source_index')
			doc.pop('source_id')
		if 'event_id' in doc.keys() :
			doc['event_desc'] = self.events[doc['event_id']][1]
			doc['severity'] = self.events[doc['event_id']][0]
		if not ('@timestamp' in doc.keys()) :
			doc['@timestamp'] = datetime.utcnow()
		dd = '%02d' % parsers.datetime(doc['@timestamp']).day
		mm = '%02d' % parsers.datetime(doc['@timestamp']).month
		yyyy = str(parsers.datetime(doc['@timestamp']).year)
		index_suffix = yyyy + '.' + mm + '.' + dd		
		res = self.es.index(index=self.watcher_index+index_suffix, doc_type='doc', body=doc)
		del doc
	
	def check_limits (self, source_doc) :
		doc = source_doc.copy()
		doc.pop('norepeat_key')
		doc.pop('counter_key')
		doc.pop('score')
		for key,value in self.limits[source_doc['event_id']].iteritems() :
			redis_counter_key = self.r.get("wlogon_top_margin|" + source_doc['counter_key'] + "|" + key)
			if redis_counter_key is not None:
				top_margin = int(redis_counter_key)
			else:
				top_margin = value[0]
			count = self.r.zcount(source_doc['counter_key'], source_doc['score'] - value[1], source_doc['score'])
			if (count > top_margin ) and (not self.r.exists(source_doc['norepeat_key'] + key)) :
				self.r.set(source_doc['norepeat_key'] + key,'allredy_messaged')
				self.r.expire(source_doc['norepeat_key']+ key, self.norepeat_time)				
				doc['period'] = key
				doc['count'] = count
				self.message(doc)
		del doc
					
	def check_new_and_old (self, source_doc) :
		doc = source_doc.copy()
		doc.pop('check_set')
		doc.pop('events_for_check')
		doc.pop('entities_for_check')
		myvalue = ''
		for entity in source_doc['entities_for_check'] :
			myvalue += source_doc[entity] + '|'
		myvalue = myvalue.strip('|')
		if self.r.zadd(source_doc['check_set'], source_doc['score'], myvalue):
			doc['event_id'] = source_doc['events_for_check']['new'][0]

			self.message(doc)
		else:
			oldscore = int( self.r.zscore(source_doc['check_set'], myvalue) )
			doc['days'] = int((source_doc['score'] - oldscore) / 86400)
			if doc['days'] > source_doc['events_for_check']['oldest'][1] :
				doc['event_id'] = source_doc['events_for_check']['oldest'][0]
				self.message(doc)
			elif doc['days'] > source_doc['events_for_check']['old'][1] :
				doc['event_id'] = source_doc['events_for_check']['old'][0]
				self.message(doc)
		del doc	

	def play_valid_network_logon (self, source_doc):
		doc = source_doc.copy()
		
		
		# Группировка по юзерам. user to target
		doc.pop('source_ip')
		doc.pop('target_host')
		
		doc['counter_key'] = "valid_logon|network|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_020|'+ source_doc['username']+ '|'
		doc['event_id'] = 'wlogon_020'		
		self.r.zadd(doc['counter_key'], source_doc['score'], source_doc['target_host'])
		self.check_limits (doc) 
		doc.pop('username')
		

		# Группировка по источникам. source_ip to target
		# исключаем логон с адреса 127.0.0.1	
		if not (source_doc['source_ip'] in ['127.0.0.1','::1']) :
			doc['counter_key'] = "valid_logon|network|per_source_ip|" + source_doc['source_ip']
			doc['norepeat_key'] = 'wlogon_021|'+ source_doc['source_ip']+ '|'
			doc['event_id'] = 'wlogon_021'
			doc['source_ip'] = source_doc['source_ip']		
			
			self.r.zadd(doc['counter_key'], source_doc['score'], source_doc['target_host'])
			self.check_limits (doc)
			doc.pop('source_ip')
		# конец группировок
		doc.pop('counter_key')
		doc.pop('norepeat_key')
		
		# target новые сетевые логоны, редкие логоны
		
		doc['target_host'] = source_doc['target_host']
		doc['check_set'] = "valid_logon|network|per_target_host|by_source_ip|" + source_doc['target_host']
		doc['source_ip'] = source_doc['source_ip']
		doc['events_for_check'] = {'new':['wlogon_022', 0],'old':['wlogon_024', 7], 'oldest':['wlogon_023', 30]}
		doc['entities_for_check'] = ['source_ip']
		
		self.check_new_and_old (doc)
		doc.pop('source_ip')

		doc['check_set'] = "valid_logon|network|per_target_host|by_user|" + source_doc['target_host']		
		doc['username'] = source_doc['username']
		doc['events_for_check'] = {'new':['wlogon_025', 0],'old':['wlogon_027', 7], 'oldest':['wlogon_026', 30]}
		doc['entities_for_check'] = ['username']
		self.check_new_and_old (doc)
		doc.pop('username')

		doc['check_set'] = "valid_logon|network|per_target_host|by_user_ip_pair|" + source_doc['target_host']		
		doc['username'] = source_doc['username']
		doc['source_ip'] = source_doc['source_ip']
		doc['events_for_check'] = {'new':['wlogon_028', 0],'old':['wlogon_030', 7], 'oldest':['wlogon_029', 30]}
		doc['entities_for_check'] = ['username','source_ip']
		self.check_new_and_old (doc)
		doc.pop('username')

		del doc
		
	def play_valid_interactive_logon(self, source_doc) :
		doc = source_doc.copy()
		
		doc.pop('target_host')
		doc['counter_key'] = "valid_logon|interactive|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_031|'+ source_doc['username'] + '|'
		doc['event_id'] = 'wlogon_031'		
		self.r.zadd(doc['counter_key'], source_doc['score'], source_doc['target_host'])
		self.check_limits (doc) 
		doc.pop('username')
		# конец группировок
		doc.pop('counter_key')
		doc.pop('norepeat_key')

		# target новые и редкие интерактивные логоны
		doc['target_host'] = source_doc['target_host']
		doc['check_set'] = "valid_logon|interactive|per_target_host|by_user|" + source_doc['target_host']		
		doc['username'] = source_doc['username']
		doc['events_for_check'] = {'new':['wlogon_032', 0],'old':['wlogon_034', 7], 'oldest':['wlogon_033', 30]}
		doc['entities_for_check'] = ['username']
		self.check_new_and_old (doc)

		del doc
	
	def play_valid_bad_logon_network (self, source_doc):
		doc = source_doc.copy()
		doc.pop('score')
		doc['event_id'] = 'wlogon_004'	
		#выводим сообщение о плохом логоне валидного юзера
		self.message(doc)

		doc['score'] = source_doc['score']
		
		item = doc['source_index'] + "|" + doc['source_id']
		# считаем события по юзеру
		doc.pop('target_host')
		doc.pop('source_ip')
		doc['counter_key'] = "valid_bad_logon|network|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_005|'+ source_doc['username'] + '|'
		doc['event_id'] = 'wlogon_005'
		doc['username'] = source_doc['username']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('username')
		
		doc['counter_key'] = "valid_bad_logon|network|per_source_ip|" + source_doc['source_ip']
		doc['norepeat_key'] = 'wlogon_006|'+ source_doc['source_ip'] + '|'
		doc['event_id'] = 'wlogon_006'
		doc['source_ip'] = source_doc['source_ip']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('source_ip')
		
		doc['counter_key'] = "valid_bad_logon|network|per_target_host|" + source_doc['target_host']
		doc['norepeat_key'] = 'wlogon_007|'+ source_doc['target_host'] + '|'
		doc['event_id'] = 'wlogon_007'
		doc['target_host'] = source_doc['target_host']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('target_host')
		
		del doc
		
	def play_valid_bad_logon_interactive (self, source_doc):
		doc = source_doc.copy()
		doc.pop('score')
		doc['event_id'] = 'wlogon_008'	

		#выводим сообщение о плохом логоне валидного юзера
		self.message(doc)
		
		doc['score'] = source_doc['score']
		
		item = doc['source_index'] + "|" + doc['source_id']
		# считаем события по юзеру
		doc.pop('target_host')
		doc['counter_key'] = "valid_bad_logon|interactive|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_009|'+ source_doc['username'] + '|'
		doc['event_id'] = 'wlogon_009'
		doc['username'] = source_doc['username']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('username')
		
		# считаем события по target_host
		doc['counter_key'] = "valid_bad_logon|interactive|per_target_host|" + source_doc['target_host']
		doc['norepeat_key'] = 'wlogon_010|'+ source_doc['target_host'] + '|'
		doc['event_id'] = 'wlogon_010'
		doc['target_host'] = source_doc['target_host']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('target_host')

		del doc
		
	def play_invalid_bad_logon_network(self, source_doc):
		doc = source_doc.copy()
		doc['event_id'] = 'wlogon_011'	
		doc.pop('score')
		#выводим сообщение о плохом логоне неизвестного юзера
		self.message(doc)
		
		doc['score'] = source_doc['score']
		
		item = doc['source_index'] + "|" + doc['source_id']
		#считаем общие события по инвалидным юзерам
		doc.pop('target_host')
		doc.pop('source_ip')
		doc.pop('username')
		doc['counter_key'] = "invalid_bad_logon|network"
		doc['norepeat_key'] = 'wlogon_012|'
		doc['event_id'] = 'wlogon_012'
		self.check_limits (doc)
		
		# считаем события по юзеру
		doc['counter_key'] = "invalid_bad_logon|network|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_013|'+ source_doc['username'] + '|'
		doc['event_id'] = 'wlogon_013'
		doc['username'] = source_doc['username']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('username')
		
		# считаем события по IP источника
		doc['counter_key'] = "invalid_bad_logon|network|per_source_ip|" + source_doc['source_ip']
		doc['norepeat_key'] = 'wlogon_014|'+ source_doc['source_ip'] + '|'
		doc['event_id'] = 'wlogon_014'
		doc['source_ip'] = source_doc['source_ip']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('source_ip')
		
		# считаем события по target_host
		doc['counter_key'] = "invalid_bad_logon|network|per_target_host|" + source_doc['target_host']
		doc['norepeat_key'] = 'wlogon_015|'+ source_doc['target_host'] + '|'
		doc['event_id'] = 'wlogon_015'
		doc['target_host'] = source_doc['target_host']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('target_host')
		
		del doc
		
	def play_invalid_bad_logon_interactive (self, source_doc) :
		doc = source_doc.copy()
		doc.pop('score')
		doc['event_id'] = 'wlogon_016'	

		#выводим сообщение о плохом логоне неизвестного юзера
		self.message(doc)
		
		doc['score'] = source_doc['score']
		
		item = doc['source_index'] + "|" + doc['source_id']
		#считаем общие события по инвалидным юзерам
		doc.pop('target_host')
		doc.pop('username')
		doc['counter_key'] = "invalid_bad_logon|interactive"
		doc['norepeat_key'] = 'wlogon_017|'
		doc['event_id'] = 'wlogon_017'
		self.check_limits (doc)
		
		# считаем события по юзеру
		doc['counter_key'] = "invalid_bad_logon|interactive|per_user|" + source_doc['username']
		doc['norepeat_key'] = 'wlogon_018|'+ source_doc['username'] + '|'
		doc['event_id'] = 'wlogon_018'
		doc['username'] = source_doc['username']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('username')
			
		# считаем события по target_host
		doc['counter_key'] = "invalid_bad_logon|interactive|per_target_host|" + source_doc['target_host']
		doc['norepeat_key'] = 'wlogon_019|'+ source_doc['target_host'] + '|'
		doc['event_id'] = 'wlogon_019'
		doc['target_host'] = source_doc['target_host']
		self.r.zadd(doc['counter_key'], source_doc['score'], item)
		self.check_limits (doc)
		doc.pop('target_host')

		del doc
		
	def search (self) :
		current_watcher_timestamp = datetime.now()
		# Запрашиваем у редиса параметр watcher_lastcheck
		if self.r.exists('logon_watcher_lastcheck') :
			logon_watcher_lastcheck = self.r.get('logon_watcher_lastcheck')
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
		res = self.es.search(index='winlogbeat-*',body=myquery)

		for hit in res['hits']['hits']:
			doc = {}
			if 'TargetUserName' in hit['_source']['event_data'] :
				username = hit['_source']['event_data']['TargetUserName'].lower()
			else:
				break
			if 'TargetDomainName' in hit['_source']['event_data'] :
				username = username + '@' + hit['_source']['event_data']['TargetDomainName'].lower()

			current_logon_time = hit['_source']['@timestamp']
			logon_type = int(hit['_source']['event_data']['LogonType'])
			logon_event_id = hit['_id']
			logon_index = hit['_index']
			
			doc['log_type'] = self.log_type
			doc['source_index'] = logon_index
			doc['source_id'] = logon_event_id
			doc['@timestamp'] = current_logon_time
			doc['username'] = username
			doc['score'] = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			doc['check_set'] = 'known_valid_logons'
			doc['events_for_check'] = {'new':['wlogon_001', 0],'old':['wlogon_003', 7], 'oldest':['wlogon_002', 30]}
			doc['entities_for_check'] = ['username']		
			self.check_new_and_old(doc)
			doc.pop('check_set')
			doc.pop('events_for_check')
			doc.pop('entities_for_check')
					
			# считаем статистику валидных логонов
			if logon_type in self.network_logon_types:
				source_ip = hit['_source']['event_data']['IpAddress']
				if source_ip is None:
					source_ip = '127.0.0.1'
				try:
					source_ip = str(IP(source_ip))
				except:
					source_ip = '127.0.0.1'
				doc['source_ip'] = source_ip
				target_host = hit['_source']['computer_name'].lower()
				if target_host in self.network_logon_excepted_target_hosts :
					del doc
					break
				doc['target_host'] = target_host
				item = doc['username']+ "|" + doc['source_ip'] + "|" + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
				if self.r.zadd("valid_logon|network", doc['score'], item) == 0 :
					del doc
					break

				self.play_valid_network_logon(doc)
				
			elif logon_type in self.interactive_logon_types:
				target_host = hit['_source']['computer_name'].lower()
				if target_host in self.interactive_logon_excepted_target_hosts :
					del doc
					break
				doc['target_host'] = target_host
				item = doc['username'] + "|"  + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
				if self.r.zadd("valid_logon|interactive", doc['score'], item) == 0 :
					del doc
					break
					
				self.play_valid_interactive_logon(doc)
			del doc	
			
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
		res = self.es.search(index='winlogbeat-*',body=myquery)

		for hit in res['hits']['hits']:
			if 'TargetUserName' in hit['_source']['event_data'] :
				username = hit['_source']['event_data']['TargetUserName'].lower()
			else:
				break
			if 'TargetDomainName' in hit['_source']['event_data'] :
				username = username + '@' + hit['_source']['event_data']['TargetDomainName'].lower()
			current_logon_time = hit['_source']['@timestamp']
			logon_type = int(hit['_source']['event_data']['LogonType'])
			logon_event_id = hit['_id']
			logon_index = hit['_index']
			doc = {}
			doc['log_type'] = self.log_type
			doc['source_index'] = logon_index
			doc['source_id'] = logon_event_id
			doc['@timestamp'] = current_logon_time
			doc['username'] = username
			doc['score'] = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
			
			if self.r.zscore("known_valid_logons", doc['username']) is not None:
				if logon_type in self.network_logon_types :
					source_ip = hit['_source']['event_data']['IpAddress']
					if source_ip is None:
						source_ip = '127.0.0.1'
					try:
						source_ip = str(IP(source_ip))
					except:
						source_ip = '127.0.0.1'
					doc['source_ip'] = source_ip
					doc['target_host'] = hit['_source']['computer_name'].lower()
					item = doc['username'] + "|" + doc['source_ip'] + "|" + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
					
					if self.r.zadd("valid_bad_logon|network", doc['score'], item) == 0 :
						del doc
						break
					self.play_valid_bad_logon_network (doc)				
	
				elif logon_type in self.interactive_logon_types :
					doc['target_host'] = hit['_source']['computer_name'].lower()
					item = doc['username'] + "|" + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
					if self.r.zadd("valid_bad_logon|interactive", doc['score'], item) == 0 :
						del doc
						break
					self.play_valid_bad_logon_interactive(doc)
					
			elif logon_type in self.network_logon_types :
				source_ip = hit['_source']['event_data']['IpAddress']
				if source_ip is None:
					source_ip = '127.0.0.1'
				try:
					source_ip = str(IP(source_ip))
				except:
					source_ip = '127.0.0.1'
				doc['source_ip'] = source_ip
				doc['target_host'] = hit['_source']['computer_name']
				item = doc['username'] + "|" + doc['source_ip'] + "|" + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
				if self.r.zadd("invalid_bad_logon|network", doc['score'], item) == 0 :
					del doc
					break
				self.play_invalid_bad_logon_network(doc)

			elif logon_type in self.interactive_logon_types :
				doc['target_host'] = hit['_source']['computer_name']
				item = doc['username'] + "|" + doc['target_host'] + "|" + doc['source_index'] + "|" + doc['source_id']
				if self.r.zadd("invalid_bad_logon|interactive", doc['score'], item) == 0 :
					del doc
					break
				self.play_invalid_bad_logon_interactive(doc)
			del doc
		self.r.set('logon_watcher_lastcheck', (current_watcher_timestamp - timedelta(seconds=10)).isoformat())
			
			
			
