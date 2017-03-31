# Role Name: openstack_cinder_storage

## abstract
This role executes install and setting cinder for storage node.

## procedures
1. install lvm2 packages
2. enable and start lvm2-lvmetad service
3. create physical volumes for cinder
4. create volume group for cinder
5. extract device names of devices with operating system
6. edit lvm.conf
7. install cinder packages
8. edit config file
9. enable and start services

## tests (serverspec)
1. check lvm2 package is installed
2. check lvm2-lvmetad service is enabled and running
3. check physical volumes are created
4. check volume group is created
5. check devices with root partition are filtered in lvm.conf
6. check cinder devices are filtered in lvm.conf
7. check cinder packages are installed
8. check cinder services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_cinder_storage:
  cinder_devices:          # devices used by cinder
    - sdb
  cinder_vg: cinder_vg     # name of volume group used by cinder
  cinder_dbpass: password  # password of cinder database 
  controller: controller   # hostname or ip of controller node
  mgmt_ip: 127.0.0.1       # ip of management network for controller node
  rabbitmq_pass: password  # password of openstack user for rabbitmq
  domain: default          # domain name of openstack environment
  cinder_pass: password    # password of cinder user 
```

## supported os
* CentOS 7
