#!/bin/bash

# Container Registry credentials (default is OSF subscriber; can be Docker Hub)
registry=${REGISTRY:-hub.foundries.io}
registry_user=${REGISTRY_USER:-this-is-ignored}
registry_passwd=${REGISTRY_PASSWD}
registry_email=${REGISTRY_EMAIL:-docker@docker.com}

# The hub variable is a bit of a misnomer.
if [ "$registry" = "hub.foundries.io" ]; then
    if [ -z "$registry_passwd" ]; then
        echo "Error: REGISTRY_PASSWD is unset; cannot log in to hub.foundries.io."
        exit 1
    fi
    hub=hub.foundries.io
elif [ "$registry" = "hub.docker.com" ]; then
    hub=opensourcefoundries
else
    hub=${HUB}
fi

if [ -z "$hub" ]; then
    echo "Error: no hub provided and no value is known."
    exit 1
fi

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
                 -e "gitci=$gitci hub=$hub" \
                 -e "brokerhost=$hostname brokeruser='' brokerpw=''" \
                 -e "registry=$registry registry_user=$registry_user" \
                 -e "registry_passwd=$registry_passwd registry_email=$registry_email" \
                 -e "ansible_python_interpreter=/usr/bin/python3" \
                 -u $gatewayuser -i $hostname, iot-gateway.yml --tags $ansibletags
