# Role Name: openstack_neutron_compute

## abstract
This role executes install and setting neutron for compute node.

## procedures
1. install packages
2. edit config file
3. enable and start services

## tests (serverspec)
1. check package is installed
2. check openstack-nova-compute service is running
3. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_neutron_compute:
  controller: controller   # hostname or ip of controller node
  rabbitmq_pass: password  # password of openstack user for rabbitmq
  domain: default          # domain name of openstack environment
  neutron_pass: password   # password of neutron user
  provider_ifname: enp0s3  # name of interface for provider network
  overlayif_ip: 127.0.0.1  # ip with interface for overlay
  region: RegionOne        # region name of openstack environment

```

## supported os
* CentOS 7
