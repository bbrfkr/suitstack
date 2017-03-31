# Role Name: openstack_horizon

## abstract
This role executes install and setting horizon for controller node.

## procedures
1.  install package
2.  edit config file with restarting services
3.  restart httpd, memcached services

## tests (serverspec)
1.  check package is installed
2.  check services are running

## tests (infrataster)
nothing

## parameters
```
---
openstack_horizon:
  controller: controller  # hostname or ip of controller node
  domain: default         # domain name of openstack environment
  timezone: Asia/Tokyo    # timezone
```

## supported os
* CentOS 7
