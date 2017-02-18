# Welcome to metricbeat 5.2.0

Metricbeat sends metrics to Elasticsearch.

## Getting Started

To get started with metricbeat, you need to set up Elasticsearch on your localhost first. After that, start metricbeat with:

     ./metricbeat  -c metricbeat.yml -e

This will start the beat and send the data to your Elasticsearch instance. To load the dashboards for metricbeat into Kibana, run:

    ./scripts/import_dashboards

For further steps visit the [Getting started](https://www.elastic.co/guide/en/beats/metricbeat/5.2/metricbeat-getting-started.html) guide.

## Documentation

Visit [Elastic.co Docs](https://www.elastic.co/guide/en/beats/metricbeat/5.2/index.html) for the full metricbeat documentation.

## Release notes

https://www.elastic.co/guide/en/beats/libbeat/5.2/release-notes-5.2.0.html
