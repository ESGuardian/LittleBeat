homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"

curl -XPUT http://127.0.0.1:9200/.kibana/index-pattern/nmap-* -d '{"title" : "nmap-*",  "timeFieldName": "@timestamp"}' 1>>$log 2>>$errlog
curl -XPUT http://127.0.0.1:9200/.kibana/index-pattern/winlogbeat-* -d '{"title" : "winlogbeat-*",  "timeFieldName": "@timestamp"}' 1>>$log 2>>$errlog
curl -XPUT http://127.0.0.1:9200/.kibana/config/4.6.1 -d '{"defaultIndex" : "nmap-*"}' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/NMAP-common-search/ -d'{
      "title": "NMAP-common-search",
      "description": "",
      "hits": 0,
      "columns": [
        "_source"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"nmap-*\",\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}},\"filter\":[],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
}' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/NMAP-hosts-by-subnet-table/ -d'{
      "title": "NMAP-хосты-по-сетям",
      "visState": "{\"title\":\"NMAP-хосты-по-сетям\",\"type\":\"table\",\"params\":{\"perPage\":5,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"ipv4\",\"customLabel\":\"Кол-во IP адресов\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"headers.http_x_nmap_target\",\"size\":100,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Сети\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "NMAP-common-search",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/NMAP-port-table/ -d'{
      "title": "NMAP-порты",
      "visState": "{\"title\":\"NMAP-порты\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"ipv4\",\"customLabel\":\"Кол-во IP адресов\"}},{\"id\":\"3\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"port.service.name\",\"size\":20,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Сервис\"}},{\"id\":\"4\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"port.number\",\"size\":100,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Порт\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"nmap-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/NMAP-by-ip-table/ -d'{
      "title": "NMAP-IP-адреса",
      "visState": "{\"title\":\"NMAP-IP-адреса\",\"type\":\"table\",\"params\":{\"perPage\":20,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"port.service.name\",\"customLabel\":\"Кол-во сервисов\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"ipv4\",\"size\":300,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"IP адреса\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "NMAP-common-search",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/NMAP-host-table/ -d'{
      "title": "NMAP-хосты",
      "visState": "{\"title\":\"NMAP-хосты\",\"type\":\"table\",\"params\":{\"perPage\":20,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"port.service.name\",\"customLabel\":\"Кол-во сервисов\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"hostname.name\",\"size\":300,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Хосты\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"nmap-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

  
curl -XPUT http://127.0.0.1:9200/.kibana/dashboard/NMAP-dash/ -d'{
      "title": "NMAP-dash",
      "hits": 0,
      "description": "",
      "panelsJSON": "[{\"col\":1,\"id\":\"NMAP-host-table\",\"panelIndex\":1,\"row\":1,\"size_x\":4,\"size_y\":6,\"type\":\"visualization\"},{\"col\":5,\"id\":\"NMAP-port-table\",\"panelIndex\":2,\"row\":4,\"size_x\":4,\"size_y\":3,\"type\":\"visualization\"},{\"col\":9,\"id\":\"NMAP-by-ip-table\",\"panelIndex\":3,\"row\":1,\"size_x\":4,\"size_y\":6,\"type\":\"visualization\"},{\"col\":5,\"id\":\"NMAP-hosts-by-subnet-table\",\"panelIndex\":4,\"row\":1,\"size_x\":4,\"size_y\":3,\"type\":\"visualization\"}]",
      "optionsJSON": "{\"darkTheme\":false}",
      "uiStateJSON": "{}",
      "version": 1,
      "timeRestore": true,
      "timeTo": "now/d",
      "timeFrom": "now/d",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}}]}"
      }
    }' 1>>$log 2>>$errlog  
curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-base/ -d'{
      "title": "WinLog-base",
      "description": "",
      "hits": 0,
      "columns": [
        "beat.hostname",
        "event_data.SubjectUserName",
        "event_data.TargetUserName",
        "event_id",
        "message"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}},\"filter\":[],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-logon-filtered/ -d'{
      "title": "WinLog-logon-filtered",
      "description": "",
      "hits": 0,
      "columns": [
        "_source"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"!event_data.TargetUserName:*$ AND !event_data.TargetUserName:\\\"ANONYMOUS LOGON\\\" AND !event_data.TargetDomainName:\\\"Window Manager\\\" AND !beat.hostname:dc1 AND !beat.hostname:dc2\",\"analyze_wildcard\":true}},\"filter\":[{\"meta\":{\"negate\":false,\"index\":\"winlogbeat-*\",\"key\":\"event_id\",\"value\":\"4624\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"event_id\":{\"query\":4624,\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}},{\"meta\":{\"negate\":true,\"index\":\"winlogbeat-*\",\"key\":\"event_data.LogonType\",\"value\":\"Как Сервис\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"event_data.LogonType\":{\"query\":\"Как Сервис\",\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}},{\"meta\":{\"negate\":true,\"index\":\"winlogbeat-*\",\"key\":\"event_data.TargetUserName\",\"value\":\"АНОНИМНЫЙ ВХОД\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"event_data.TargetUserName\":{\"query\":\"АНОНИМНЫЙ ВХОД\",\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}}],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-logon-failure/ -d'{
      "title": "WinLog-logon-failure",
      "description": "",
      "hits": 0,
      "columns": [
        "_source"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"event_id:4625 AND !event_data.TargetUserName:*$\",\"analyze_wildcard\":true}},\"filter\":[{\"meta\":{\"negate\":true,\"index\":\"winlogbeat-*\",\"key\":\"event_data.LogonType\",\"value\":\"Как Сервис\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"event_data.LogonType\":{\"query\":\"Как Сервис\",\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}}],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-security/ -d'{
      "title": "WinLog-security",
      "description": "",
      "hits": 0,
      "columns": [
        "event_id",
        "message",
        "event_data.NewProcessName",
        "event_data.SubjectUserName",
        "event_data.TargetUserName"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[{\"meta\":{\"negate\":false,\"index\":\"winlogbeat-*\",\"key\":\"log_name\",\"value\":\"Security\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"log_name\":{\"query\":\"Security\",\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}}],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-system/ -d'{
      "title": "WinLog-system",
      "description": "",
      "hits": 0,
      "columns": [
        "event_id",
        "message",
        "event_data.NewProcessName",
        "event_data.SubjectUserName",
        "event_data.TargetUserName"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}},\"filter\":[{\"$state\":{\"store\":\"appState\"},\"meta\":{\"alias\":null,\"disabled\":false,\"index\":\"winlogbeat-*\",\"key\":\"log_name\",\"negate\":false,\"value\":\"System\"},\"query\":{\"match\":{\"log_name\":{\"query\":\"System\",\"type\":\"phrase\"}}}}],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-service-install/ -d'{
      "title": "WinLog-service-install",
      "description": "",
      "hits": 0,
      "columns": [
        "event_id",
        "beat.hostname",
        "event_data.ServiceAccount",
        "event_data.ServiceName",
        "event_data.ServiceFileName"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}},\"filter\":[{\"meta\":{\"negate\":false,\"index\":\"winlogbeat-*\",\"key\":\"log_name\",\"value\":\"Security\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"log_name\":{\"query\":\"Security\",\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}},{\"meta\":{\"negate\":false,\"index\":\"winlogbeat-*\",\"key\":\"event_id\",\"value\":\"4697\",\"disabled\":false,\"alias\":null},\"query\":{\"match\":{\"event_id\":{\"query\":4697,\"type\":\"phrase\"}}},\"$state\":{\"store\":\"appState\"}}],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/search/WinLog-process-created-search/ -d'{
      "title": "WinLog-process-created-search",
      "description": "",
      "hits": 0,
      "columns": [
        "event_id",
        "message",
        "event_data.NewProcessName",
        "event_data.SubjectUserName",
        "event_data.TargetUserName"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"event_id:4688\",\"analyze_wildcard\":true}},\"filter\":[],\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}},\"require_field_match\":false,\"fragment_size\":2147483647}}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-service-install/ -d'{
      "title": "WinLog-установка-службы-в-системе",
      "visState": "{\"title\":\"WinLog-установка-службы-в-системе\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Кол-во\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"beat.hostname\",\"size\":300,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Хост\"}},{\"id\":\"3\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_data.ServiceName\",\"size\":100,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Сервис\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-service-install",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-system-by-event-id/ -d'{
      "title": "WinLog-system-ID-событий",
      "visState": "{\"title\":\"WinLog-system-ID-событий\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Кол-во\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_id\",\"size\":1000,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"ID события\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-system",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-security-by-event-id/ -d'{
      "title": "WinLog-security-ID-событий",
      "visState": "{\"title\":\"WinLog-security-ID-событий\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Кол-во\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_id\",\"size\":1000,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"ID события\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-security",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-new-process/ -d'{
      "title": "WinLog-новый-процесс",
      "visState": "{\"title\":\"WinLog-новый-процесс\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"beat.hostname\",\"customLabel\":\"На хостах\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_data.NewProcessBareName\",\"size\":1000,\"order\":\"asc\",\"orderBy\":\"1\",\"customLabel\":\"Зарегистрированные процессы\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-process-created-search",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-logon-fail/ -d'{
      "title": "WinLog-неудачные-входы",
      "visState": "{\"title\":\"WinLog-неудачные-входы\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Кол-во попыток\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_data.TargetUserName\",\"size\":500,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Неудачные входы\"}},{\"id\":\"3\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"beat.hostname\",\"customLabel\":\"Кол-во хостов\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-logon-failure",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-logons/ -d'{
      "title": "WinLog-входы",
      "visState": "{\"title\":\"WinLog-входы\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Кол-во входов\"}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_data.TargetUserName\",\"size\":500,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Успешные входы\"}},{\"id\":\"3\",\"type\":\"cardinality\",\"schema\":\"metric\",\"params\":{\"field\":\"beat.hostname\",\"customLabel\":\"Кол-во хостов\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-logon-filtered",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-count/ -d'{
      "title": "WinLog-всего-событий",
      "visState": "{\"title\":\"WinLog-всего-событий\",\"type\":\"metric\",\"params\":{\"handleNoResults\":true,\"fontSize\":\"48\"},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"Событий из журналов Windows\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-event_IDs/ -d'{
      "title": "WinLog-ID-событий",
      "visState": "{\"title\":\"WinLog-ID-событий\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_id\",\"size\":1000,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"ID События\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "savedSearchId": "WinLog-base",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-logon-types/ -d'{
      "title": "WinLog-тип-входа",
      "visState": "{\"title\":\"WinLog-тип-входа\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"event_data.LogonType\",\"size\":15,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Типы входа\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-by-task/ -d'{
      "title": "WinLog-события",
      "visState": "{\"title\":\"WinLog-события\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"task\",\"size\":100,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Событие\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-by-host/ -d'{
      "title": "WinLog-хосты",
      "visState": "{\"title\":\"WinLog-хосты\",\"type\":\"table\",\"params\":{\"perPage\":25,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{}},{\"id\":\"2\",\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"beat.hostname\",\"size\":500,\"order\":\"asc\",\"orderBy\":\"_term\",\"customLabel\":\"Имя хоста\"}}],\"listeners\":{}}",
      "uiStateJSON": "{}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/WinLog-events-by-time/ -d'{
      "title": "WinLog-события-по-времени",
      "visState": "{\"title\":\"New Visualization\",\"type\":\"histogram\",\"params\":{\"shareYAxis\":true,\"addTooltip\":true,\"addLegend\":true,\"scale\":\"linear\",\"mode\":\"stacked\",\"times\":[],\"addTimeMarker\":false,\"defaultYExtents\":false,\"setYExtents\":false,\"yAxis\":{}},\"aggs\":[{\"id\":\"1\",\"type\":\"count\",\"schema\":\"metric\",\"params\":{}},{\"id\":\"2\",\"type\":\"date_histogram\",\"schema\":\"segment\",\"params\":{\"field\":\"@timestamp\",\"interval\":\"auto\",\"customInterval\":\"2h\",\"min_doc_count\":1,\"extended_bounds\":{}}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"colors\":{\"Count\":\"#508642\"},\"legendOpen\":false}}",
      "description": "",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"winlogbeat-*\",\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

  
curl -XPUT http://127.0.0.1:9200/.kibana/dashboard/WinLog-dash/ -d'{
      "title": "WinLog-dash",
      "hits": 0,
      "description": "",
      "panelsJSON": "[{\"col\":1,\"id\":\"WinLog-by-host\",\"panelIndex\":1,\"row\":1,\"size_x\":2,\"size_y\":10,\"type\":\"visualization\"},{\"col\":6,\"id\":\"WinLog-events-by-time\",\"panelIndex\":2,\"row\":1,\"size_x\":3,\"size_y\":2,\"type\":\"visualization\"},{\"col\":1,\"id\":\"WinLog-by-task\",\"panelIndex\":3,\"row\":11,\"size_x\":3,\"size_y\":5,\"type\":\"visualization\"},{\"col\":1,\"columns\":[\"beat.hostname\",\"event_data.SubjectUserName\",\"event_data.TargetUserName\",\"message\"],\"id\":\"WinLog-base\",\"panelIndex\":4,\"row\":16,\"size_x\":12,\"size_y\":10,\"sort\":[\"@timestamp\",\"desc\"],\"type\":\"search\"},{\"col\":3,\"id\":\"WinLog-logon-types\",\"panelIndex\":5,\"row\":3,\"size_x\":3,\"size_y\":3,\"type\":\"visualization\"},{\"col\":4,\"id\":\"WinLog-event_IDs\",\"panelIndex\":6,\"row\":11,\"size_x\":3,\"size_y\":5,\"type\":\"visualization\"},{\"col\":3,\"id\":\"WinLog-count\",\"panelIndex\":7,\"row\":1,\"size_x\":3,\"size_y\":2,\"type\":\"visualization\"},{\"col\":3,\"id\":\"WinLog-logons\",\"panelIndex\":8,\"row\":6,\"size_x\":6,\"size_y\":5,\"type\":\"visualization\"},{\"col\":6,\"id\":\"WinLog-logon-fail\",\"panelIndex\":9,\"row\":3,\"size_x\":3,\"size_y\":3,\"type\":\"visualization\"},{\"col\":9,\"id\":\"WinLog-new-process\",\"panelIndex\":10,\"row\":6,\"size_x\":4,\"size_y\":5,\"type\":\"visualization\"},{\"col\":7,\"id\":\"WinLog-security-by-event-id\",\"panelIndex\":11,\"row\":11,\"size_x\":3,\"size_y\":5,\"type\":\"visualization\"},{\"col\":10,\"id\":\"WinLog-system-by-event-id\",\"panelIndex\":12,\"row\":11,\"size_x\":3,\"size_y\":5,\"type\":\"visualization\"},{\"col\":9,\"id\":\"WinLog-service-install\",\"panelIndex\":13,\"row\":1,\"size_x\":4,\"size_y\":5,\"type\":\"visualization\"}]",
      "optionsJSON": "{\"darkTheme\":false}",
      "uiStateJSON": "{\"P-1\":{\"spy\":{\"mode\":{\"fill\":false,\"name\":null}}}}",
      "version": 1,
      "timeRestore": true,
      "timeTo": "now/d",
      "timeFrom": "now/d",
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}}]}"
      }
    }' 1>>$log 2>>$errlog
    

