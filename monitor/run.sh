#!/usr/bin/env bash

# Start Grafana
service grafana-server start

# Start Prometheus
cd /prometheus/prometheus-2.14.0.linux-amd64
./prometheus
