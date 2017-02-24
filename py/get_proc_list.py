#! /usr/bin/python
# -*- coding: utf8 -*-
#
# этот скрипт создает текстовый файл ~/reports/proc_list.txt
# со строками вида proc_name:severity:comment
# файл создается на основе поиска имен процессов записанных в индексе winlogbeat-* 
# и сопоставления из со списком известных процессов в индексе win-proc-list.
# Следует использовать совместно со скриптом set_proc_list.py.
# Способ использования такой: 
# 1) запускаем get_proc_list.py
# 2) открываем файл proc_list.txt в текстовом редакторе и заменяем "Неизвестный" на
# что-нибудь более причличное, например, "Обычный","Разрешенный" или "Зловредный"
# 3) запускаем set_proc_list.py и он корректирует данные в индексе win-proc-list
#
# командная строка get_proc_list.py [int_days] [0|1]
#    int_days - кол-во суток от сегодня, за которое смотреть события в winlogbeat-*
#    0 - выводить только список процессов с severity Неизвестный
#    1 - выводить весь список процессов (удобно, если хотим переопределить severity)
#
# esguardian@outlook.com
# https://github.com/ESGuardian
#


import sys
from datetime import date, timedelta, datetime
from pytz import timezone
from elasticsearch import Elasticsearch 
import codecs

def getindexes (es,prefix,dates) :
    indexes = []
    for strdate in dates:
        testindex = prefix + strdate
        if es.indices.exists(index=testindex):
            indexes.append(testindex)
    return indexes

def check_process (es,name) :
    name_query =   {"query":{"term":{ "proc_name":name}}}
    if es.indices.exists(index="win-proc-list") :
        try:
            res = es.search(index="win-proc-list",body=name_query)
            for hit in res['hits']['hits']:
                return (hit["_source"]["severity"],hit["_source"]["comment"])
            
        except Exception as e:
            return (u"Ошибка ", unicode(e))
    return (u"Неизвестный",u"Авто")
    
period = 1
full = 0
if len(sys.argv) > 2:
    full = int(sys.argv[1])
if len(sys.argv) > 1:
    period = int(sys.argv[1])

today = datetime.utcnow().date()
enddate=today.strftime('%Y.%m.%d')
startdate=(today - timedelta(days=period)).strftime('%Y.%m.%d')
dates = []
for i in xrange(0,period+1):
    dates.append((today - timedelta(days=i)).strftime('%Y.%m.%d'))
    
es = Elasticsearch()
myquery =   {"query":\
                    {\
                        "constant_score":{ "filter":{"bool":{"must":{"term":{"log_name":"Security"}},"should":{"term":{ "event_id":4688 }}}} }\
                    },\
                    "aggs": {\
                        "by_procname": {"terms": {"field": "event_data.NewProcessBareName", "size":10000}}\
                    }\
                }
proc_list = []

outfilename='proc_list.txt'
outfullpath='~/reports/' + outfilename
with codecs.open(outfullpath, 'a', encoding="utf8") as out:
    try:
        res = es.search(index=getindexes(es,"winlogbeat-",dates),body=myquery,request_timeout=60)
        for procname in res['aggregations']['by_procname']['buckets']:
            new_proc_name = procname['key']
            if not new_proc_name in proc_list:
                proc_list.append(new_proc_name)
                (severity,comment) = check_process (es,new_proc_name)
                if severity == u"Неизвестный" or full != 0 :
                    str = new_proc_name + u":" + severity + u":" + comment + "\n"
                    out.write(str)
                
    except Exception as e: 
        print "ERROR: " +  unicode(e)
        pass
out.close
