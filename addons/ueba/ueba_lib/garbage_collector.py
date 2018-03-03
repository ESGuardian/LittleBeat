#! /usr/bin/python
# -*- coding: utf8 -*-
from datetime import date, timedelta, datetime
from iso8601utils import parsers
import codecs
import time
from IPy import IP

class garbage_collector (object):
	def __init__(self, redis_conn):
		self.r = redis_conn
		
	def collect (self) :
		cursor = 0		
		donext = True
		margin = int(time.mktime(datetime.now().timetuple())) - 3600*24*60
		for item in self.r.scan_iter():
			if self.r.type(item) == 'zset' :
				self.r.zremrangebyscore(item, 0, margin)
					