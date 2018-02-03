#! /usr/bin/python
# -*- coding: utf8 -*-
#
# этот скрипт читает текстовый файл /opt/littlebeat/install/proc_list.txt
# со строками вида proc_name:severity:comment
# и обновляет данные индекса win-proc-list данными из файла
# Следует использовать совместно со скриптом get_proc_list.py.
# Способ использования такой: 
# 1) запускаем get_proc_list.py
# 2) открываем файл proc_list.txt в текстовом редакторе и заменяем "Неизвестный" на
# что-нибудь более причличное, например, "Обычный","Разрешенный" или "Зловредный"
# 3) запускаем set_proc_list.py и он корректирует данные в индексе win-proc-list
#
# командная строка: set_proc_list.py 
#
# esguardian@outlook.com
# https://github.com/ESGuardian
#


import sys
from datetime import date, timedelta, datetime
from pytz import timezone
from elasticsearch import Elasticsearch 
import codecs


    
es = Elasticsearch()

outfilename='proc_list.txt'
outfullpath='/opt/littlebeat/data/' + outfilename
with codecs.open(outfullpath, 'r', encoding="utf8") as source:
    content = source.readlines()
    content = [x.strip() for x in content]
source.close

index = "win-proc-list"
    

for item in content:
    (proc_name,severity,comment) = item.split(":")
    if es.indices.exists(index=index):
        # удаляем старые документы с этим proc_name, если они есть
        res = es.search(index=index, body={"query": {"match":{"proc_name":proc_name}}})
        ids = [x['_id'] for x in res['hits']['hits']]
        if len(ids) > 0:
            for id in ids :
                res = es.delete(index=index, doc_type=index, id=id) 
            es.indices.refresh(index=index)
    # вставляем новый документ
    doc = {
        'proc_name': proc_name,
        'severity': severity,
        'comment': comment,
        '@timestamp':datetime.utcnow()
    }
    res = es.index(index=index, doc_type=index, body=doc)
    
   
