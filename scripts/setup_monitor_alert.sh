#!/bin/bash
##Setup monitor alert
## User local: source/bash/sh $0
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_monitor_alert.sh)

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DOCKER_CMD="docker"
DOCKER_PS_CMD="$DOCKER_CMD ps -a"
DOCKER_KILL="$DOCKER_CMD kill"
DOCKER_RM="$DOCKER_CMD rm"
DOCKER_RUN_CMD="$DOCKER_CMD run"
NAME="alert"

function checkDockerPermissions() {
    docker ps > /dev/null
    if [ $? = 1 ];then
        echo -e "your $RED [$USER] $NC not privilege docker" 
        echo -e "please run $RED [sudo bash] $NC first"
        echo -e "Or docker not install "
        exit 1
    fi
}

function checkDockerCompose() {
    docker-compose --version > /dev/null 2>&1
    if [ $? -eq 127 ];then
        echo -e "$RED docker-compose command not found $NC"
        echo -e "Please install it first"
        exit 1
    fi
}

function check-runing() {
    $DOCKER_PS_CMD | grep $NAME > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo -e "${RED} alert server is running ${NC}"
        read -p "[Ctrl + c exit!]; Enter any key to stop it." anykey
        echo "Stopping..."
        stop
        read -p "[Ctrl + c exit!]; Enter any key to continue the setup." anykey
    fi
}

function stop() {
    $DOCKER_KILL $NAME > /dev/null 2>&1
}

function clean() {
     $DOCKER_RM $NAME > /dev/null 2>&1
}

function set-var() {
    HOSTNAME=$(hostname)
    MKDIR="mkdir -p"

    IOTEX_ALERT_HOME="$IOTEX_HOME/alert"
    MONITOR_CONTAINER="iotex-monitor"
    ALERTMANAGER_IMAGE="prom/alertmanager"

    IOTEX_PROM_CONGIF_FILE="$IOTEX_HOME/monitor/prometheus.yml"
    IOTEX_PROM_RULE_FILE="$IOTEX_HOME/monitor/alert.rules"

    DOCKER_RUN_OPTS="-d --restart on-failure --name $NAME -v ${IOTEX_ALERT_HOME}:/alertmanager -p 9093:9093"
    ALERT_PARAMS="--config.file=/alertmanager/etc/alertmanager.yml --storage.path=/alertmanager"
}

function check-monitor() {
    $DOCKER_PS_CMD | grep $MONITOR_CONTAINER > /dev/null
    if [ $? -ne 0 ];then
        echo -e "${RED} Your monitor $MONITOR_CONTAINER is not running or created.${NC}"
        exit 1
    fi
}

function make-workspace() {
    $MKDIR ${IOTEX_ALERT_HOME}/{etc,template}
    chmod o+w ${IOTEX_ALERT_HOME} -R
}

function download-files() {
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/alert/alertmanager.yml.tmpl > $IOTEX_ALERT_HOME/etc/alertmanager.yml.tmpl || exit 1
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/alert.rules > $IOTEX_HOME/monitor/alert.rules || exit 1
    curl -Ss https://raw.githubusercontent.com/prometheus/alertmanager/master/template/default.tmpl > $IOTEX_ALERT_HOME/template/default.tmpl || exit 1
    curl -Ss https://raw.githubusercontent.com/prometheus/alertmanager/master/template/email.html > $IOTEX_ALERT_HOME/template/email.html || exit 1
}

function setup-config() {
    sed -e "s/_SMTP_HOST_/$USER_EMAIL_HOST/" \
        -e "s/_SMTP_PORT_/$USER_EMAIL_PORT/" \
        -e "s/_EMAIL_/$USER_EMAIL_NAME/" \
        -e "s/_PASSWORD_/$USER_EMAIL_PASS/" \
        $IOTEX_ALERT_HOME/etc/alertmanager.yml.tmpl > $IOTEX_ALERT_HOME/etc/alertmanager.yml
}

function startup() {
    $DOCKER_PS_CMD | grep $NAME > /dev/null 2>&1
    if [ $? -eq 0 ];then
        stop
        clean
    fi

    $DOCKER_RUN_CMD $DOCKER_RUN_OPTS \
                    $ALERTMANAGER_IMAGE \
                    $ALERT_PARAMS
}

function add-alert() {
    echo -e "${YELLOW} Now, The settings will change the monitor server's configuration file ${NC}"
    echo -e "${YELLOW} and add the address of the link alert service. ${NC}"
    echo -e "${YELLOE} Please enter the address to connect to this service from the monitor server ${NC}"
    read -p "The host of this alert server [ Default is hostname $HOSTNAME ]:" alertserver
    alert=${alertserver:-"$HOSTNAME"}
    if [ -f $IOTEX_PROM_CONGIF_FILE ]; then
        grep 'alerting' $IOTEX_PROM_CONGIF_FILE > /dev/null 2>&1
        if [ $? -ne 0 ];then
            echo '

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "'$alert':9093"

rule_files:
  - "alert.rules"
' >> $IOTEX_PROM_CONGIF_FILE
        fi
    else
        echo -e "${RED} There is no prometheus.yml file ${NC}"
        echo -e "${RED} You need to setup the monitor server  first ${NC}"
        exit 1
    fi
}

function restart-monitor () {
    echo -e "${YELLOW} Need restart monitor ${NC}"
    echo -e "${YELLOW} Monitor server is restarting... ${NC}"
    $DOCKER_CMD restart $MONITOR_CONTAINER || exit 1
}

function main() {
    checkDockerPermissions    
    checkDockerCompose

    check-runing

    defaultdatadir="$HOME/iotex-var"
    read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
    IOTEX_HOME=${inputdir:-"$defaultdatadir"}

    while :
    do
        read -p "[Ctrl + c exit!]; else input email smtp host:" emailhost
        if [ -x $emailhost ];then
            echo -e "${YELLOW} Email smtp host must be set."
        else
            break
        fi
    done

    read -p "[Ctrl + c exit!]; else input email smtp port [ Default is 587 ]:" emailport

    while :
    do
        read -p "[Ctrl + c exit!]; else input email user name:" username
        if [ -x $username ];then
            echo -e "${YELLOW} Email user name must be set."
        else
            break
        fi
    done

    while :
    do
        echo "[Ctrl + c exit!]; else input email user password:"
        read -s userpass
        if [ -x $userpass ];then
            echo -e "${YELLOW} Email user password must be set."
        else
            break
        fi
    done

    USER_EMAIL_HOST=${emailhost}
    USER_EMAIL_PORT=${emailport:-"587"}
    USER_EMAIL_NAME=${username}
    USER_EMAIL_PASS=${userpass}

    set-var

    check-monitor

    make-workspace

    download-files

    setup-config

    startup

    add-alert

    restart-monitor

    echo -e "${YELLOW} Alert server is running ${NC}"
    echo -e "${YELLOW} You can visit http://localhost:9090/alerts to view alerts. ${NC}"
}

main
