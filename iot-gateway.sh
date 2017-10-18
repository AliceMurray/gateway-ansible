#!/bin/bash

# Container Registry credentials (private or dockerhub)
registry=${REGISTRY:hub.docker.com}
registry_user=${REGISTRY_USER:docker}
registry_passwd=${REGISTRY_PASSWD:docker}
registry_email=${REGISTRY_EMAIL:docker@docker.com}

# Gateway target hostname
hostname=${GW_HOSTNAME:-10.0.1.3}
gatewayuser=osf

# Location where hawkbit is running
if [ -z "$GITCI" ] ; then
	if which ip >/dev/null 2>&1 ; then
		echo "probing linux host for routable ip address"
		defip=$(ip route get 8.8.8.8 | head -n1 | awk '{print $NF}')
	else
		echo "probing mac host for routable ip address"
		defip=$(route get 8.8.8.8 | grep interface | awk '{print $2}' | xargs ifconfig | grep 'inet ' | awk '{print $2}')
	fi
fi
[ -z "$defip" ] && defip=10.0.1.2
gitci=${GITCI:-$defip}

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
                 -e "registry=$registry registry_user=$registry_user" \
                 -e "registry_passwd=$registry_passwd registry_email=$registry_email" \
                 -e "ansible_python_interpreter=/usr/bin/python3" \
                 -u $gatewayuser -i $hostname, iot-gateway.yml --tags $ansibletags
