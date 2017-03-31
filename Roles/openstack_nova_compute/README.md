# Role Name: openstack_nova_compute

## abstract
This role executes install and setting nova for compute node.

## procedures
1. install package
2. edit config file
3. enable and start services

## tests (serverspec)
1. check package is installed
2. check config of hardware support for virtualization is set
3. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_nova_compute:
  mgmt_ip: 127.0.0.1       # ip address of compute node
  controller: localhost    # hostname or ip of controller node
  rabbitmq_pass: password  # password of openstack user for rabbitmq
  domain: default          # domain name of openstack environment
  nova_pass: password      # password of nova user
  console_keymap: ja       # keymap used by console
```

## supported os
* CentOS 7
