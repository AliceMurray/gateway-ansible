#!/bin/bash

usage="
$(basename "$0") [-h] [-r] [-p] [-g] [-m] -- script to execute iot-gateway ansible playbook

where:
    -h  show this help text
    -r  override docker registry {default=hub.foundries.io}
    -p  override docker registry password
    -g  override target IP/hostname
    -m  override IP of device management system (i.e. leshan/hawkbit)

"

#process command-line options / overrides
while getopts ":help:r:p:g:m:" option; do
  case $option in
    r ) REGISTRY=${OPTARG} ;;
    p ) REGISTRY_PASSWD=${OPTARG} ;;
    g ) GW_HOSTNAME=${OPTARG} ;;
    m ) MGMT_SERVER=${OPTARG} ;;
    * ) echo "$usage"
        exit ;;
  esac
done
shift $((OPTIND -1))

# Container Registry credentials (default is OSF subscriber; can be Docker Hub)
registry=${REGISTRY:-hub.foundries.io}
registry_user=${REGISTRY_USER:-this-is-ignored}
registry_passwd=${REGISTRY_PASSWD:-YOUR-FOUNDRIES.IO-APP-KEY}
registry_email=${REGISTRY_EMAIL:-docker@docker.com}

# The hub variable is a bit of a misnomer.
if [ "$registry" = "hub.foundries.io" ]; then
    if [ -z "$registry_passwd" ]; then
        echo "Error: REGISTRY_PASSWD is unset; cannot log in to hub.foundries.io."
        echo "$usage" >&2
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
    echo "$usage" >&2
    exit 1
fi

# Gateway target hostname
hostname=${GW_HOSTNAME:-10.0.1.3}
gatewayuser=osf

# Location where hawkbit is running
if [ -z "$MGMT_SERVER" ] ; then
	if which ip >/dev/null 2>&1 ; then
		echo "probing linux host for routable ip address"
		defip=$(ip route get 8.8.8.8 | head -n1 | sed -e 's/.*src //' | cut -d\  -f1)
	else
		echo "probing mac host for routable ip address"
		defip=$(route get 8.8.8.8 | grep interface | awk '{print $2}' | xargs ifconfig | grep 'inet ' | awk '{print $2}')
	fi
fi
[ -z "$defip" ] && defip=10.0.1.2
mgmt_server=${MGMT_SERVER:-$defip}

#Cloudmqtt configuration
cloudmqtthost=${CLOUDMQTT_HOST:-m12.cloudmqtt.com}
cloudmqttport=${CLOUDMQTT_PORT:-18645}
cloudmqttuser=${CLOUDMQTT_USER:-username}
cloudmqttpw=${CLOUDMQTT_PASSWD:-password}

#First argument Ansible tags
ansibletags=${1:-gateway}

#output what is about to be configuration
echo "
  Calling iot-gateway as:
     GW_HOSTNAME=$hostname \\
     MGMT_SERVER=$mgmt_server \\
     REGISTRY=$REGISTRY \\
     HUB=$hub \\
     REGISTRY_PASSWD=$registry_passwd \\
     ansibletags=$ansibletags \\
     ./$(basename "$0")
    "

#run ansible playbook
ansible-playbook -e "mqttuser=$cloudmqttuser mqttpass=$cloudmqttpw mqtthost=$cloudmqtthost mqttport=$cloudmqttport "\
                 -e "mgmt_server=$mgmt_server hub=$hub" \
                 -e "brokerhost=$hostname brokeruser='' brokerpw=''" \
                 -e "registry=$registry registry_user=$registry_user" \
                 -e "registry_passwd=$registry_passwd registry_email=$registry_email" \
                 -e "ansible_python_interpreter=/usr/bin/python3" \
                 -u $gatewayuser -i "${hostname}," iot-gateway.yml --tags $ansibletags
