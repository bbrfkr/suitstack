# Role Name: openstack_nova_controller

## abstract
This role executes install and setting nova for controller node.

## procedures
1.  create databases
2.  grant privileges to access databases
3.  create nova user
4.  add admin role to nova user
5.  create nova service entity
6.  create endpoints for nova
7.  install packages
8.  edit config file
9.  create keyfiles dir
10. deploy service databases
11. enable and start services

## tests (serverspec)
1.  check databases are created
2.  check privileges of database is set
3.  check nova user is created
4.  check admin role is granted to nova user
5.  check nova service entity is created
6.  check endpoints for nova are created
7.  check packages are installed
8.  check servcie databases is deployed
9.  check services are enabled and started
10. check cpu allocation ratio is specified
11. check ram allocation ratio is specified

## tests (infrataster)
nothing

## parameters
```
---
openstack_nova_controller:
  mariadb_pass: password            # root password of mariadb
  novadb_pass: password             # password of nova databases
  scripts_dir: /root/openrc_files   # location of openrc files
  nova_pass: password               # password of nova user
  domain: default                   # domain name of openstack environment
  region: RegionOne                 # region name of openstack environment
  controller: localhost             # hostname or ip of controller node
  mgmt_ip: 127.0.0.1                # ip of management network for controller node
  rabbitmq_pass: password           # password of openstack user for rabbitmq
  keyfiles_dir: /var/suit_keyfiles  # location of keyfiles
  cpu_allocation_ratio: 16.0        # virtual cpu to physical cpu allocation ratio
  ram_allocation_ratio: 1.5         # virtual ram to physical ram allocation ratio
```

## supported os
* CentOS 7
