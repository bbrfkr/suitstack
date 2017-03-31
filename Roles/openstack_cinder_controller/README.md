# Role Name: openstack_cinder_controller

## abstract
This role executes install and setting cinder for controller node.

## procedures
1.  create cinder database
2.  grant privileges to access database
3.  create cinder user
4.  add admin role to cinder user
5.  create cinder, cinderv2 service entity
6.  create endpoints for cinder, cinderv2
7.  install package
8.  edit config file
9.  create keyfiles dir
10. deploy service database
11. edit config file with openstack-nova-api
12. restart openstack-nova-api service
13. enable and start services

## tests (serverspec)
1.  check cinder database is created
2.  check privileges of database is set
3.  check cinder user is created
4.  check admin role is granted to cinder user
5.  check cinder service entities are created
6.  check endpoints for cinder are created
7.  check package is installed
8.  check cinder servcie database is deployed
9.  check openstack-nova-api service is running
10. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_cinder_controller:
  mariadb_pass: password            # root password of mariadb
  cinder_dbpass: password           # password of cinder database
  scripts_dir: /root/openrc_files   # location of openrc files 
  cinder_pass: password             # password of cinder user
  domain: default                   # domain name of openstack environment
  region: RegionOne                 # region name of openstack environment
  controller: localhost             # hostname or ip of controller node
  mgmt_ip: 127.0.0.1                # ip of management network for controller node 
  rabbitmq_pass: password           # password of openstack user for rabbitmq
  keyfiles_dir: /var/suit_keyfiles  # location of keyfiles 
```

## supported os
* CentOS 7
