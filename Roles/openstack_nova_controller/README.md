# Role Name: openstack_nova_controller

## abstract
This role executes install and setting nova for controller node.

## procedures
1.  create databases
2.  grant privileges to access databases
3.  create nova and placement users
4.  add admin role to nova and placement users
5.  create nova and placement service entities
6.  create endpoints for nova and placement
7.  install packages
8.  edit config file
9.  supply bug fix to enable access to the placement api
10. create keyfiles dir
11. deploy service databases
12. create cell1 cell
13. enable and start services

## tests (serverspec)
1.  check databases are created
2.  check privileges of database are set
3.  check nova and placement users are created
4.  check admin role is granted to nova and placement users
5.  check nova and placement service entities are created
6.  check endpoints for nova and placement are created
7.  check packages are installed
8.  check servcie databases are deployed
9.  check cell0 and cell1 cells are registered
10. check services are enabled and started
11. check cpu allocation ratio is specified
12. check ram allocation ratio is specified

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
  placement_pass: password          # password of placement user
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
