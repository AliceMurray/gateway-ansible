#!/bin/bash

# Gateway target hostname
hostname=${GW_HOSTNAME:-10.0.1.3}
gatewayuser=osf

# Location where hawkbit is running
gitci=${GITCI:-10.0.1.2}

#Cloudmqtt configuration
cloudmqtthost=${CLOUDMQTT_HOST:-m12.cloudmqtt.com}
cloudmqttport=${CLOUDMQTT_PORT:-18645}
cloudmqttuser=${CLOUDMQTT_USER:-username}
cloudmqttpw=${CLOUDMQTT_PASSWD:-password}

#First argument Ansible tags
ansibletags=${1:-gateway}

ansible-playbook -e "mqttuser=$cloudmqttuser mqttpass=$cloudmqttpw mqtthost=$cloudmqtthost mqttport=$cloudmqttport "\
                 -e "gitci=$gitci" \
                 -e "brokerhost=$hostname brokeruser='' brokerpw=''" \
                 -u $gatewayuser -i $hostname, iot-gateway.yml --tags $ansibletags
