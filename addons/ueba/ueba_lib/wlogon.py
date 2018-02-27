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
		
		

	def message (self, **kwargs) :
	
		doc = {}
		for key,value in kwargs.iteritems():
			doc[key] = value
		
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
				last_hour = score - 3600
				count = self.r.zcount("valid_logon|network|per_user|" + username, last_hour, score)
				if count > 5 :
					if not self.r.exists('wlogon_20|'+ username + '|last_hour') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_020', username=username, period=u"Последний час", count=count)
						self.r.set('wlogon_20|' + username + '|last_hour', 'allready_messaged')
						self.r.expire('wlogon_20|' + username + '|last_hour', 600)					
				last_day = score - 86400
				count = self.r.zcount("valid_logon|network|per_user|" + username, last_day, score)
				if count > 10 :
					if not self.r.exists('wlogon_20|'+ username + '|last_day') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_020', username=username, period=u"Последние сутки", count=count)
						self.r.set('wlogon_20|' + username + '|last_day', 'allready_messaged')
						self.r.expire('wlogon_20|' + username + '|last_day', 600)					
				last_weak = score - 86400*7
				count = self.r.zcount("valid_logon|network|per_user|" + username, last_weak, score)
				if count > 100 :
					if not self.r.exists('wlogon_20|'+ username + '|last_weak') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_020', username=username, period=u"Последняя неделя", count=count)
						self.r.set('wlogon_20|' + username + '|last_weak', 'allready_messaged')
						self.r.expire('wlogon_20|' + username + '|last_weak', 600)
					
					
				# Группировка по источникам. source_ip to target
				# исключаем логон с адреса 127.0.0.1	
				if not (source_ip in ['127.0.0.1','::1']) :
					self.r.zadd("valid_logon|network|per_source_ip|" + source_ip, score, target_host)					
					last_hour = score - 3600
					count = self.r.zcount("valid_logon|network|per_source_ip|" + source_ip, last_hour, score)						
					if count > 5 :
						if not self.r.exists('wlogon_21|'+ source_ip + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_021', source_ip=source_ip, period=u"Последний час", count=count)
							self.r.set('wlogon_21|' + source_ip + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_21|' + source_ip + '|last_hour', 600)
					last_day = score - 86400
					count = self.r.zcount("valid_logon|network|per_source_ip|" + source_ip, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_21|'+ source_ip + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_021', source_ip=source_ip, period=u"Последние сутки", count=count)
							self.r.set('wlogon_21|' + source_ip + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_21|' + source_ip + '|last_day', 600)
					last_weak = score - 86400*7
					count = self.r.zcount("valid_logon|network|per_source_ip|" + source_ip, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_21|'+ source_ip + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_021', source_ip=source_ip, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_21|' + source_ip + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_21|' + source_ip + '|last_weak', 600)
						
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
				last_hour = score - 3600
				count = self.r.zcount("valid_logon|interactive|per_user|" + username, last_hour, score)
				if count > 5 :
					if not self.r.exists('wlogon_31|'+ username + '|last_hour') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_031', username=username, period=u"Последний час", count=count)
						self.r.set('wlogon_31|' + username + '|last_hour', 'allready_messaged')
						self.r.expire('wlogon_31|' + username + '|last_hour', 600)
					
				last_day = score - 86400
				count = self.r.zcount("valid_logon|interactive|per_user|" + username, last_day, score)
				if count > 10 :
					if not self.r.exists('wlogon_31|'+ username + '|last_day') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_031', username=username, period=u"Последние сутки", count=count)
						self.r.set('wlogon_31|' + username + '|last_day', 'allready_messaged')
						self.r.expire('wlogon_31' + username + '|last_day', 600)
					
				last_weak = score - 86400*7
				count = self.r.zcount("valid_logon|interactive|per_user|" + username, last_weak, score)
				if count > 100 :
					if not self.r.exists('wlogon_31|'+ username + '|last_weak') :
						self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_031', username=username, period=u"Последняя неделя", count=count)
						self.r.set('wlogon_31|' + username + '|last_weak', 'allready_messaged')
						self.r.expire('wlogon_31|' + username + '|last_weak', 600)
						
					
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
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|network|per_user|" + username, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_005|'+ username + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_005', username=username, period=u"Последний час", count=count)
							self.r.set('wlogon_005|' + username + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_005|' + username + '|last_hour', 600)

					last_day = score - 86400
					count = self.r.zcount("valid_bad_logon|network|per_user|" + username, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_005|'+ username + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_005', username=username, period=u"Последние сутки", count=count)
							self.r.set('wlogon_005|' + username + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_005|' + username + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("valid_bad_logon|network|per_user|" + username, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_005|'+ username + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_005', username=username, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_005|' + username + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_005|' + username + '|last_weak', 600)
						
					
					# считаем события по IP источника
					self.r.zadd("valid_bad_logon|network|per_source_ip|" + source_ip, score, item)
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|network|per_source_ip|" + source_ip, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_006|'+ source_ip + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_006', source_ip=source_ip, period=u"Последний час", count=count)
							self.r.set('wlogon_006|' + source_ip + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_006|' + source_ip + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("valid_bad_logon|network|per_source_ip|" + source_ip, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_006|'+ source_ip + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_006', source_ip=source_ip, period=u"Последние сутки", count=count)
							self.r.set('wlogon_006|' + source_ip + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_006|' + source_ip + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("valid_bad_logon|network|per_source_ip|" + source_ip, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_006|'+ source_ip + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_006', source_ip=source_ip, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_006|' + source_ip + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_006|' + source_ip + '|last_weak', 600)
						
						
					# считаем события по target_host
					self.r.zadd("valid_bad_logon|network|per_target_host|" + target_host, score, item)
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|network|per_target_host|" + target_host, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_007|'+ target_host + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_007', target_host=target_host, period=u"Последний час", count=count)
							self.r.set('wlogon_007|' + target_host + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_007|' + target_host + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("valid_bad_logon|network|per_target_host|" + target_host, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_007|'+ target_host + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_007', target_host=target_host, period=u"Последние сутки", count=count)
							self.r.set('wlogon_007|' + target_host + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_007|' + target_host + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("valid_bad_logon|network|per_target_host|" + target_host, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_007|'+ target_host + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_007', target_host=target_host, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_007|' + target_host + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_007|' + target_host + '|last_weak', 600)
						
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
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|interactive|per_user|" + username, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_009|'+ username + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_009', username=username, period=u"Последний час", count=count)
							self.r.set('wlogon_009|' + username + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_009|' + username + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("valid_bad_logon|interactive|per_user|" + username, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_009|'+ username + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_009', username=username, period=u"Последние сутки", count=count)
							self.r.set('wlogon_009|' + username + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_009|' + username + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("valid_bad_logon|interactive|per_user|" + username, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_009|'+ username + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_009', username=username, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_009|' + username + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_009|' + username + '|last_weak', 600)
						
					
					# считаем события по target_host
					self.r.zadd("valid_bad_logon|interactive|per_target_host|" + target_host, score, item)
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|interactive|per_target_host|" + target_host, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_010|'+ target_host + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_010', target_host=target_host, period=u"Последний час", count=count)
							self.r.set('wlogon_010|' + target_host + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_010|' + target_host + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("valid_bad_logon|interactive|per_target_host|" + target_host, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_010|'+ target_host + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_010', target_host=target_host, period=u"Последние сутки", count=count)
							self.r.set('wlogon_010|' + target_host + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_010|' + target_host + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("valid_bad_logon|interactive|per_target_host|" + target_host, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_010|'+ target_host + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_010', target_host=target_host, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_010|' + target_host + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_010|' + target_host + '|last_weak', 600)
						
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
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|network", last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_012|' + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_012', period=u"Последний час", count=count)
							self.r.set('wlogon_012|' + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_012|' + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|network", last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_012|' + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_012', period=u"Последние сутки", count=count)
							self.r.set('wlogon_012|' + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_012|' + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|network", last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_012|' + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_012', period=u"Последняя неделя", count=count)
							self.r.set('wlogon_012|' + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_012|' + '|last_weak', 600)
						
					
					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("invalid_bad_logon|network|per_user|" + username, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|network|per_user|" + username, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_013|'+ username + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_013', username=username, period=u"Последний час", count=count)
							self.r.set('wlogon_013|' + username + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_013|' + username + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|network|per_user|" + username, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_013|'+ username + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_013', username=username, period=u"Последние сутки", count=count)
							self.r.set('wlogon_013|' + username + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_013|' + username + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|network|per_user|" + username, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_013|'+ username + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_013', username=username, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_013|' + username + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_013|' + username + '|last_weak', 600)
						
					
					# считаем события по IP источника
					self.r.zadd("invalid_bad_logon|network|per_source_ip|" + source_ip, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|network|per_source_ip|" + source_ip, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_014|'+ source_ip + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_014', source_ip=source_ip, period=u"Последний час", count=count)
							self.r.set('wlogon_014|' + source_ip + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_014|' + source_ip + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|network|per_source_ip|" + source_ip, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_014|'+ source_ip + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_014', source_ip=source_ip, period=u"Последние сутки", count=count)
							self.r.set('wlogon_014|' + source_ip + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_014|' + source_ip + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|network|per_source_ip|" + source_ip, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_014|'+ source_ip + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_014', source_ip=source_ip, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_014|' + source_ip + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_014|' + source_ip + '|last_weak', 600)
						
						
					# считаем события по target_host
					self.r.zadd("invalid_bad_logon|network|per_target_host|" + target_host, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|network|per_target_host|" + target_host, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_015|'+ target_host + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_015', target_host=target_host, period=u"Последний час", count=count)
							self.r.set('wlogon_015|' + target_host + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_015|' + target_host + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|network|per_target_host|" + target_host, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_015|'+ target_host + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_015', target_host=target_host, period=u"Последние сутки", count=count)
							self.r.set('wlogon_015|' + target_host + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_015|' + target_host + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|network|per_target_host|" + target_host, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_015|'+ target_host + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_015', target_host=target_host, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_015|' + target_host + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_015|' + target_host + '|last_weak', 600)
						
				elif logon_type in self.interactive_logon_types :
					target_host = hit['_source']['computer_name']
					item = username + "|" + target_host + "|" + logon_index + "|" + logon_event_id
					score = int(time.mktime(parsers.datetime(current_logon_time).timetuple()))
					if self.r.zadd("invalid_bad_logon|interactive", score, item) == 0 :
						break
					self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_016', username=username,target_host=target_host)

					#считаем общие события по инвалидным юзерам
					last_hour = score - 3600
					count = self.r.zcount("valid_bad_logon|interactive", last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_017|' + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_017', period=u"Последний час", count=count)
							self.r.set('wlogon_017|' + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_017|' + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|interactive", last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_017|' + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_017', period=u"Последние сутки", count=count)
							self.r.set('wlogon_017|' + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_017|' + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|interactive", last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_017|' + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_017', period=u"Последняя неделя", count=count)
							self.r.set('wlogon_017|' + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_017|' + '|last_weak', 600)
						
						
					item = logon_index + "|" + logon_event_id
					# считаем события по юзеру
					self.r.zadd("invalid_bad_logon|interactive|per_user|" + username, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|interactive|per_user|" + username, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_018|'+ username + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_018', username=username, period=u"Последний час", count=count)
							self.r.set('wlogon_018|' + username + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_018|' + username + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|interactive|per_user|" + username, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_018|'+ username + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_018', username=username, period=u"Последние сутки", count=count)
							self.r.set('wlogon_018|' + username + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_018|' + username + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|interactive|per_user|" + username, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_018|'+ username + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_018', username=username, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_018|' + username + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_018|' + username + '|last_weak', 600)
					
					# считаем события по target_host
					self.r.zadd("invalid_bad_logon|interactive|per_target_host|" + target_host, score, item)
					last_hour = score - 3600
					count = self.r.zcount("invalid_bad_logon|interactive|per_target_host|" + target_host, last_hour, score)
					if count > 5 :
						if not self.r.exists('wlogon_019|'+ target_host + '|last_hour') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_019', target_host=target_host, period=u"Последний час", count=count)
							self.r.set('wlogon_019|' + target_host + '|last_hour', 'allready_messaged')
							self.r.expire('wlogon_019|' + target_host + '|last_hour', 600)
						
					last_day = score - 86400
					count = self.r.zcount("invalid_bad_logon|interactive|per_target_host|" + target_host, last_day, score)
					if count > 10 :
						if not self.r.exists('wlogon_019|'+ target_host + '|last_day') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_019', target_host=target_host, period=u"Последние сутки", count=count)
							self.r.set('wlogon_019|' + target_host + '|last_day', 'allready_messaged')
							self.r.expire('wlogon_019|' + target_host + '|last_day', 600)
						
					last_weak = score - 86400*7
					count = self.r.zcount("invalid_bad_logon|interactive|per_target_host|" + target_host, last_weak, score)
					if count > 100 :
						if not self.r.exists('wlogon_019|'+ target_host + '|last_weak') :
							self.message(log_type=self.log_type, source_index=logon_index, source_id=logon_event_id, timestamp=current_logon_time, event_id= 'wlogon_019', target_host=target_host, period=u"Последняя неделя", count=count)
							self.r.set('wlogon_019|' + target_host + '|last_weak', 'allready_messaged')
							self.r.expire('wlogon_019|' + target_host + '|last_weak', 600)
						
				
		self.r.set('logon_watcher_lastcheck', (current_watcher_timestamp - timedelta(seconds=10)).isoformat())
			
			
			
