# Using Docker Install prometheus

## Custom config  
reference: https://prometheus.io/docs/prometheus/latest/configuration/configuration/

**get system eth0 ip**  

> hostip=$(hostname -i|awk '{print$1}')

    cat <<EOF> ~/prometheus.yml
    global:
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
    rule_files:
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
        - targets: ['localhost:9090']
      - job_name: 'iotex-testnet'
        static_configs:
        - targets: ["${hostip}:8080"]
    EOF

## get dcoker image and run prometheus

    sudo docker pull prom/prometheus

    sudo docker run -d \
      -p 9090:9090 \
      -v ~/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus \
      --config.file=/etc/prometheus/prometheus.yml

## check prometheus running
    sudo netstat -nltp|grep 9090

## visit http://${hostip}:9090/targets




## Using Docker Install Grafana

    docker pull grafana/grafana
    docker run -d --name=grafana -p 3000:3000 grafana/grafana

## check grafana running

    sudo netstat -nltp|grep 3000
