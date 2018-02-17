github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
apt update
apt install docker.io -y
docker volume create ossec-data
docker run -d --restart=always -p 1514:1514/udp -p 1515:1515/tcp -v ossec-data:/var/ossec/data --name ossec-server esguardian/ossec-docker
chmod 711 /var/lib/docker/volumes
cd /tmp
if [ -e "wazuh_dash.json" ]; then
	rm wazuh_dash.json
fi
wget $github_url/addons/ossec/kibana/wazuh_dash.json
curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/index-pattern/wazuh-alerts-*
curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @wazuh_dash.json
cd /etc/logstash/templates
if [ ! -e "/etc/logstash/templates/wazuh-elastic6-template-alerts.json" ]; then
	wget $github_url/addons/ossec/logstash/templates/wazuh-elastic6-template-alerts.json
else
	rm /etc/logstash/templates/wazuh-elastic6-template-alerts.json
	wget $github_url/addons/ossec/logstash/templates/wazuh-elastic6-template-alerts.json
fi
cd /etc/logstash/conf.d
if [ ! -e "/logstash/conf.d/02-wazuh.conf" ]; then
	wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
else
	rm /logstash/conf.d/02-wazuh.conf
	wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
fi
service logstash restart

