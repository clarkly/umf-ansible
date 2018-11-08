#!/bin/bash

ansible-playbook -i /etc/ansible/roles/zabbix-agent/hostnode  /etc/ansible/roles/zabbix-agent/zabbix-agent.yml -e action=install
