homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"

curl -XPUT http://127.0.0.1:9200/.kibana/index-pattern/wazuh-alerts-* -d '{"title" : "wazuh-alerts-*",  "timeFieldName": "@timestamp"}' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/search/wazuh-alerts/ -d'{
      "title": "wazuh-alerts",
      "description": "",
      "hits": 0,
      "columns": [
        "host",
        "rule.description",
        "rule.level",
        "full_log"
      ],
      "sort": [
        "@timestamp",
        "desc"
      ],
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"index\":\"wazuh-alerts-*\",\"highlightAll\":true,\"version\":true,\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}},\"filter\":[]}"
      }
}' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-total/ -d'{
      "title": "Wazuh Всего событий",
      "visState": "{\"title\":\"Wazuh Всего событий\",\"type\":\"metric\",\"params\":{\"addTooltip\":true,\"addLegend\":false,\"type\":\"gauge\",\"gauge\":{\"verticalSplit\":false,\"autoExtend\":false,\"percentageMode\":false,\"gaugeType\":\"Metric\",\"gaugeStyle\":\"Full\",\"backStyle\":\"Full\",\"orientation\":\"vertical\",\"colorSchema\":\"Green to Red\",\"gaugeColorMode\":\"None\",\"useRange\":false,\"colorsRange\":[{\"from\":0,\"to\":100}],\"invertColors\":false,\"labels\":{\"show\":true,\"color\":\"black\"},\"scale\":{\"show\":false,\"labels\":false,\"color\":\"#333\",\"width\":2},\"type\":\"simple\",\"style\":{\"fontSize\":\"48\",\"bgFill\":\"#000\",\"bgColor\":false,\"labelColor\":false,\"subText\":\"\"}}},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"defaultColors\":{\"0 - 100\":\"rgb(0,104,55)\"}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-events-by-level/ -d'{
      "title": "Wazuh Уровень событий",
      "visState": "{\"title\":\"Wazuh Уровень событий\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false,\"sort\":{\"columnIndex\":null,\"direction\":null},\"showTotal\":false,\"totalFunc\":\"sum\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"rule.level\",\"size\":20,\"order\":\"desc\",\"orderBy\":\"_term\",\"customLabel\":\"Уровень\"}},{\"id\":\"4\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"rule.description\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Описание\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
    curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-events-by-host/ -d'{
      "title": "Wazuh события по хостам",
      "visState": "{\"title\":\"Wazuh события по хостам\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false,\"sort\":{\"columnIndex\":null,\"direction\":null},\"showTotal\":false,\"totalFunc\":\"sum\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"host\",\"size\":1000,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Хост\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-cis/ -d'{
      "title": "Wazuh CIS",
      "visState": "{\"title\":\"Wazuh CIS\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false,\"sort\":{\"columnIndex\":null,\"direction\":null},\"showTotal\":false,\"totalFunc\":\"sum\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"rule.cis\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"CIS\"}},{\"id\":\"3\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"title\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Правило\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog
    
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-cve/ -d'{
      "title": "Wazuh CVE",
      "visState": "{\"title\":\"Wazuh CVE\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false,\"sort\":{\"columnIndex\":null,\"direction\":null},\"showTotal\":false,\"totalFunc\":\"sum\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"rule.cve\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"CVE\"}},{\"id\":\"3\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"title\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Название\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

  
curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-pci-dss/ -d'{
      "title": "Wazuh PCI DSS",
      "visState": "{\"title\":\"Wazuh PCI DSS\",\"type\":\"table\",\"params\":{\"perPage\":10,\"showPartialRows\":false,\"showMeticsAtAllLevels\":false,\"sort\":{\"columnIndex\":null,\"direction\":null},\"showTotal\":false,\"totalFunc\":\"sum\"},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"rule.pci_dss\",\"size\":200,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"PCI DSS\"}},{\"id\":\"3\",\"enabled\":true,\"type\":\"terms\",\"schema\":\"bucket\",\"params\":{\"field\":\"title\",\"size\":300,\"order\":\"desc\",\"orderBy\":\"1\",\"customLabel\":\"Правило\"}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog  

curl -XPUT http://127.0.0.1:9200/.kibana/visualization/wazuh-timeline/ -d'{
      "title": "Wazuh timeline",
      "visState": "{\"title\":\"Wazuh timeline\",\"type\":\"histogram\",\"params\":{\"grid\":{\"categoryLines\":false,\"style\":{\"color\":\"#eee\"}},\"categoryAxes\":[{\"id\":\"CategoryAxis-1\",\"type\":\"category\",\"position\":\"bottom\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\"},\"labels\":{\"show\":true,\"truncate\":100},\"title\":{\"text\":\"@timestamp per 30 minutes\"}}],\"valueAxes\":[{\"id\":\"ValueAxis-1\",\"name\":\"LeftAxis-1\",\"type\":\"value\",\"position\":\"left\",\"show\":true,\"style\":{},\"scale\":{\"type\":\"linear\",\"mode\":\"normal\"},\"labels\":{\"show\":true,\"rotate\":0,\"filter\":false,\"truncate\":100},\"title\":{\"text\":\"кол-во\"}}],\"seriesParams\":[{\"show\":\"true\",\"type\":\"histogram\",\"mode\":\"stacked\",\"data\":{\"label\":\"кол-во\",\"id\":\"1\"},\"valueAxis\":\"ValueAxis-1\",\"drawLinesBetweenPoints\":true,\"showCircles\":true}],\"addTooltip\":true,\"addLegend\":true,\"legendPosition\":\"right\",\"times\":[],\"addTimeMarker\":false},\"aggs\":[{\"id\":\"1\",\"enabled\":true,\"type\":\"count\",\"schema\":\"metric\",\"params\":{\"customLabel\":\"кол-во\"}},{\"id\":\"2\",\"enabled\":true,\"type\":\"date_histogram\",\"schema\":\"segment\",\"params\":{\"field\":\"@timestamp\",\"interval\":\"auto\",\"customInterval\":\"2h\",\"min_doc_count\":1,\"extended_bounds\":{}}}],\"listeners\":{}}",
      "uiStateJSON": "{\"vis\":{\"colors\":{\"кол-во\":\"#447EBC\"}}}",
      "description": "",
      "savedSearchId": "wazuh-alerts",
      "version": 1,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[]}"
      }
    }' 1>>$log 2>>$errlog

curl -XPUT http://127.0.0.1:9200/.kibana/dashboard/wazuh-main/ -d'{
      "title": "Wazuh Главная",
      "hits": 0,
      "description": "",
      "panelsJSON": "[{\"col\":1,\"id\":\"wazuh-total\",\"panelIndex\":1,\"row\":1,\"size_x\":2,\"size_y\":2,\"type\":\"visualization\"},{\"col\":1,\"id\":\"wazuh-timeline\",\"panelIndex\":2,\"row\":3,\"size_x\":2,\"size_y\":3,\"type\":\"visualization\"},{\"col\":3,\"id\":\"wazuh-events-by-host\",\"panelIndex\":3,\"row\":1,\"size_x\":4,\"size_y\":5,\"type\":\"visualization\"},{\"col\":7,\"id\":\"wazuh-events-by-level\",\"panelIndex\":4,\"row\":1,\"size_x\":6,\"size_y\":5,\"type\":\"visualization\"},{\"col\":1,\"id\":\"wazuh-cis\",\"panelIndex\":5,\"row\":6,\"size_x\":6,\"size_y\":5,\"type\":\"visualization\"},{\"col\":7,\"id\":\"wazuh-pci-dss\",\"panelIndex\":6,\"row\":6,\"size_x\":6,\"size_y\":5,\"type\":\"visualization\"},{\"col\":1,\"id\":\"wazuh-cve\",\"panelIndex\":7,\"row\":11,\"size_x\":4,\"size_y\":6,\"type\":\"visualization\"},{\"size_x\":8,\"size_y\":6,\"panelIndex\":8,\"type\":\"search\",\"id\":\"wazuh-alerts\",\"col\":5,\"row\":11,\"columns\":[\"host\",\"rule.description\",\"rule.level\",\"full_log\"],\"sort\":[\"@timestamp\",\"desc\"]}]",
      "optionsJSON": "{\"darkTheme\":false}",
      "uiStateJSON": "{\"P-1\":{\"vis\":{\"defaultColors\":{\"0 - 100\":\"rgb(0,104,55)\"}}},\"P-2\":{\"vis\":{\"legendOpen\":false}},\"P-3\":{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}},\"P-4\":{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}},\"P-5\":{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}},\"P-6\":{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}},\"P-7\":{\"vis\":{\"params\":{\"sort\":{\"columnIndex\":null,\"direction\":null}}}}}",
      "version": 1,
      "timeRestore": true,
      "timeTo": "now/d",
      "timeFrom": "now/d",
      "refreshInterval": {
        "display": "Off",
        "pause": false,
        "value": 0
      },
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"filter\":[{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}}],\"highlightAll\":true,\"version\":true}"
      }
    }' 1>>$log 2>>$errlog