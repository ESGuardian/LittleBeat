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
			'wlogon_005': [5,u"ПРЕВЫШЕН ПОРОГ. Количество неверных логонов валидного юзера превысило порог за период."],
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
			'wlogon_005': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_006': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_007': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_009': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_010': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_012': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_013': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_014': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_015': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_017': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_018': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_019': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_020': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_021': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			'wlogon_031': {'hour':[5,3600], 'day':[10,86400], 'weak':[100,604800]},
			
		}
		self.norepeat_time = 600
		
		

	def message (self, **kwargs) :
	
		doc = {}
		for key,value in kwargs.iteritems():
			doc[key] = value
		if 'norepeat_key' in doc.keys() :
			if self.r.exists(doc['norepeat_key']) :
				return
			else :
				self.r.set(doc['norepeat_key'],'allredy_messaged')
				self.r.expire(doc['norepeat_key'], self.norepeat_time)
				doc.pop('norepeat_key')
		
		if ('source_index' in doc.keys()) and ('source_id' in doc.keys()) :
			doc['source_url'] = self.kibana_base_url + '/app/kibana#/doc/winlogbeat-*/' + doc['source_index'] + '/winlogbeat?id=' + doc['source_id']
			doc.pop('source_index')
			doc.pop('source_id')
		if 'event_id' in doc.keys() :
			doc['event_desc'] = self.events[doc['event_id']][1]
			doc['severity'] = self.events[doc['event_id']][0]
		if 'timestamp' in doc.keys() :
			doc['@timestamp'] = doc['timestamp']
			doc.pop('timestamp')
		else :
			doc['@timestamp'] = datetime.utcnow()
		dd = '%02d' % parsers.datetime(doc['@timestamp']).day
		mm = '%02d' % parsers.datetime(doc['@timestamp']).month
		yyyy = str(parsers.datetime(doc['@timestamp']).year)
		index_suffix = yyyy + '.' + mm + '.' + dd
		
		res = self.es.index(index=self.watcher_index+index_suffix, doc_type='doc', body=doc)

		

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
			
			if self.r.sismember("known_valid_logons", username):
				last_logon_time = self.r.get(username+'|last_logon_time')
				delta = (parsers.datetime(last_logon_time) - parsers.datetime(current_logon_time)).days
				if delta > 30 :
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_002', username=username, days=delta)
				elif delta > 7 :
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_003', username=username, days=delta)	
			else:
				self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_001', username=username)
				self.r.sadd("known_valid_logons", username)
			self.r.set(username+'|last_logon_time', current_logon_time)
			self.r.set(username+'|last_logon_event', logon_index + "|" + logon_event_id)
			# считаем статистику валидных логонов
			if logon_type in self.network_logon_types:
				source_ip = hit['_source']['event_data']['IpAddress']
				if source_ip is None:
					source_ip = '127.0.0.1'
				try:
					source_ip = str(IP(source_ip))
				except:
					source_ip = '127.0.0.1'
				target_host = hit['_source']['computer_name'].lower()
				if target_host in self.network_logon_excepted_target_hosts :
					break
				item = username + "|" + source_ip + "|" + target_host + "|" + logon_index + "|" + logon_event_id
				score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
				if self.r.zadd("valid_logon|network", score, item) == 0 :
					break
				# Группировка по юзерам. user to target
				self.r.zadd("valid_logon|network|per_user|" + username, score, target_host)
				for key,value in self.limits['wlogon_020'].iteritems() :
					count = self.r.zcount("valid_logon|network|per_user|" + username, score - value[1], score)
					if count > value[0] :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_020', username=username, period=key, count=count, norepeat_key='wlogon_020|'+ username + '|' + key)
	
				# Группировка по источникам. source_ip to target
				# исключаем логон с адреса 127.0.0.1	
				if not (source_ip in ['127.0.0.1','::1']) :
					self.r.zadd("valid_logon|network|per_source_ip|" + source_ip, score, target_host)
					for key,value in self.limits['wlogon_021'].iteritems() :
						count = self.r.zcount("valid_logon|network|per_source_ip|" + source_ip, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_021', source_ip=source_ip, period=key, count=count, norepeat_key= 'wlogon_021|'+ source_ip + '|' + key)

				# target новые сетевые логоны, редкие логоны
				oldscore = self.r.zscore ("valid_logon|network|per_target_host|by_source_ip|" + target_host, source_ip)
				
				if self.r.zadd("valid_logon|network|per_target_host|by_source_ip|" + target_host, score, source_ip):
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_022', target_host=target_host, source_ip=source_ip)
				else :
					days = int((score - int(oldscore)) / 86400)
					if days > 30 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_023', target_host=target_host,source_ip=source_ip, days=days)
					elif days > 7 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_024', target_host=target_host,source_ip=source_ip, days=days)
						
				oldscore = self.r.zscore ("valid_logon|network|per_target_host|by_user|" + target_host, username)
				
				if self.r.zadd("valid_logon|network|per_target_host|by_user|" + target_host, score, username):
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_025', target_host=target_host, username=username)
				else :
					days = int((score - int(oldscore)) / 86400)
					if days > 30 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_026', target_host=target_host,username=username, days=days)
					elif days > 7 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_027', target_host=target_host,username=username, days=days)
						
				oldscore = self.r.zscore ("valid_logon|network|per_target_host|by_user_ip_pair|" + target_host, username + "|" + source_ip)
				
				if self.r.zadd("valid_logon|network|per_target_host|by_user_ip_pair|" + target_host, score, username + "|" + source_ip):
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_028', target_host=target_host, username=username, source_ip=source_ip)
				else :
					days = int((score - int(oldscore)) / 86400)
					if days > 30 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_029', target_host=target_host,username=username, source_ip=source_ip, days=days)
					elif days > 7 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_030', target_host=target_host,username=username, source_ip=source_ip, days=days)
				
			if logon_type in self.interactive_logon_types:
				target_host = hit['_source']['computer_name'].lower()
				if target_host in self.interactive_logon_excepted_target_hosts :
					break
				item = username + "|" + target_host + "|" + logon_index + "|" + logon_event_id
				score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
				if self.r.zadd("valid_logon|interactive", score, item) == 0 :
					break
				# Группировка по юзерам. user to target
				
				self.r.zadd("valid_logon|interactive|per_user|" + username, score, target_host)
				for key,value in self.limits['wlogon_031'].iteritems() :
					count = self.r.zcount("valid_logon|interactive|per_user|" + username, score - value[1], score)
					if count > value[0] :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_031', username=username, period=key, count=count, norepeat_key='wlogon_031|'+ username + '|' + key)

				# target новые и редкие интерактивные логоны
				oldscore = self.r.zscore ("valid_logon|interactive|per_target_host|by_user|" + target_host, username)
				
				if self.r.zadd("valid_logon|interactive|per_target_host|by_user|" + target_host, score, username):
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_032', target_host=target_host, username=username)
				else :
					days = int((score - int(oldscore)) / 86400)
					if days > 30 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_033', target_host=target_host,username=username, days=days)
					elif days > 7 :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_034', target_host=target_host,username=username, days=days)
			
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
			
			if self.r.sismember("known_valid_logons", username):
				if logon_type in self.network_logon_types :
					source_ip = hit['_source']['event_data']['IpAddress']
					if source_ip is None:
						source_ip = '127.0.0.1'
					try:
						source_ip = str(IP(source_ip))
					except:
						source_ip = '127.0.0.1'
					target_host = hit['_source']['computer_name'].lower()
					item = username + "|" + source_ip + "|" + target_host + "|" + logon_index + "|" + logon_event_id
					score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
					if self.r.zadd("valid_bad_logon|network", score, item) == 0 :
						break
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_004', username=username, source_ip=source_ip, target_host=target_host)

					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("valid_bad_logon|network|per_user|" + username, score, item)
					for key,value in self.limits['wlogon_005'].iteritems() :
						count = self.r.zcount("valid_bad_logon|network|per_user|" + username, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_005', username=username, period=key, count=count, norepeat_key='wlogon_005|'+ username + '|' + key)

					# считаем события по IP источника
					self.r.zadd("valid_bad_logon|network|per_source_ip|" + source_ip, score, item)
					for key,value in self.limits['wlogon_006'].iteritems() :
						count = self.r.zcount("valid_bad_logon|network|per_source_ip|" + source_ip, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_006', source_ip=source_ip, period=key, count=count, norepeat_key='wlogon_006|'+ source_ip + '|' + key)
	
					# считаем события по target_host
					self.r.zadd("valid_bad_logon|network|per_target_host|" + target_host, score, item)
					for key,value in self.limits['wlogon_007'].iteritems() :
						count = self.r.zcount("valid_bad_logon|network|per_target_host|" + target_host, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_007', target_host=target_host, period=key, count=count, norepeat_key='wlogon_007|'+ target_host + '|' + key)
	
				elif logon_type in self.interactive_logon_types :
					target_host = hit['_source']['computer_name'].lower()
					item = username + "|" + target_host + "|" + logon_index + "|" + logon_event_id
					score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
					if self.r.zadd("valid_bad_logon|interactive", score, item) == 0 :
						break
						
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_008', username=username,target_host=target_host)

					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("valid_bad_logon|interactive|per_user|" + username, score, item)
					for key,value in self.limits['wlogon_009'].iteritems() :
						count = self.r.zcount("valid_bad_logon|interactive|per_user|" + username, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_009', username=username, period=key, count=count, norepeat_key='wlogon_009|'+ username + '|' + key)

					# считаем события по target_host
					self.r.zadd("valid_bad_logon|interactive|per_target_host|" + target_host, score, item)
					for key,value in self.limits['wlogon_010'].iteritems() :
						count = self.r.zcount("valid_bad_logon|interactive|per_target_host|" + target_host, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_010', target_host=target_host, period=key, count=count, norepeat_key='wlogon_010|'+ target_host + '|' + key)
					
						
			else:
				if logon_type in self.network_logon_types :
					source_ip = hit['_source']['event_data']['IpAddress']
					if source_ip is None:
						source_ip = '127.0.0.1'
					try:
						source_ip = str(IP(source_ip))
					except:
						source_ip = '127.0.0.1'
					target_host = hit['_source']['computer_name']
					item = username + "|" + source_ip + "|" + target_host + "|" + logon_index + "|" + logon_event_id
					score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
					if self.r.zadd("invalid_bad_logon|network", score, item) == 0 :
						break
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_011', username=username, source_ip=source_ip, target_host=target_host)

					#считаем общие события по инвалидным юзерам
					for key,value in self.limits['wlogon_012'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|network", score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_012', period=key, count=count, norepeat_key='wlogon_012|' + key)	

					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("invalid_bad_logon|network|per_user|" + username, score, item)
					for key,value in self.limits['wlogon_013'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|network|per_user|" + username, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_013', username=username, period=key, count=count, norepeat_key='wlogon_013|'+ username + '|' + key)

					# считаем события по IP источника
					self.r.zadd("invalid_bad_logon|network|per_source_ip|" + source_ip, score, item)
					for key,value in self.limits['wlogon_014'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|network|per_source_ip|" + source_ip, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_014', source_ip=source_ip, period=key, count=count, norepeat_key='wlogon_014|'+ source_ip + '|' + key)

					# считаем события по target_host
					self.r.zadd("invalid_bad_logon|network|per_target_host|" + target_host, score, item)
					for key,value in self.limits['wlogon_015'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|network|per_target_host|" + target_host, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_015', target_host=target_host, period=key, count=count, norepeat_key='wlogon_015|'+ target_host + '|' + key)

				elif logon_type in self.interactive_logon_types :
					target_host = hit['_source']['computer_name']
					item = username + "|" + target_host + "|" + logon_index + "|" + logon_event_id
					score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
					if self.r.zadd("invalid_bad_logon|interactive", score, item) == 0 :
						break
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_016', username=username,target_host=target_host)

					#считаем общие события по инвалидным юзерам
					for key,value in self.limits['wlogon_017'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|interactive", score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_017', period=key, count=count, norepeat_key='wlogon_017|' + key)
			
					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("invalid_bad_logon|interactive|per_user|" + username, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|interactive|per_user|" + username, last_hour, score)
					for key,value in self.limits['wlogon_018'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|interactive|per_user|" + username, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_018', username=username, period=key, count=count, norepeat_key='wlogon_018|'+ username + '|' + key)

					# считаем события по target_host
					self.r.zadd("invalid_bad_logon|interactive|per_target_host|" + target_host, score, item)
					for key,value in self.limits['wlogon_019'].iteritems() :
						count = self.r.zcount("invalid_bad_logon|interactive|per_target_host|" + target_host, score - value[1], score)
						if count > value[0] :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_019', target_host=target_host, period=key, count=count, norepeat_key='wlogon_019|'+ target_host + '|' + key)
					
				
		self.r.set('logon_watcher_lastcheck', (current_watcher_timestamp - timedelta(seconds=10)).isoformat())
			
			
			
