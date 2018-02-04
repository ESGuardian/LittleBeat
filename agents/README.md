# Welcome to winlogbeat 6.1.3

Winlogbeat ships Windows event logs to Elasticsearch or Logstash.

## Getting Started

To get started with winlogbeat, you need to set up Elasticsearch on your localhost first. After that, start winlogbeat with:

     ./winlogbeat -c winlogbeat.yml -e

This will start the beat and send the data to your Elasticsearch instance. To load the dashboards for winlogbeat into Kibana, run:

    ./winlogbeat setup -e

For further steps visit the [Getting started](https://www.elastic.co/guide/en/beats/winlogbeat/6.1/winlogbeat-getting-started.html) guide.

## Documentation

Visit [Elastic.co Docs](https://www.elastic.co/guide/en/beats/winlogbeat/6.1/index.html) for the full winlogbeat documentation.

## Release notes

https://www.elastic.co/guide/en/beats/libbeat/6.1/release-notes-6.1.3.html
