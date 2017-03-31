# Role Name: openstack_neutron_controller

## abstract
This role executes install and setting neutron for controller node.

## procedures
1.  create neutron database
2.  grant privileges to access database
3.  create neutron user
4.  add admin role to neutron user
5.  create neutron service entity
6.  create endpoints for neutron
7.  install packages
8.  edit config file
9.  create keyfiles dir
10. create plugin.ini symbolic link
11. deploy service database
12. restart openstack-nova-api service
13. enable and start services

## tests (serverspec)
1.  check neutron database are created
2.  check privileges of database is set
3.  check neutron user is created
4.  check admin role is granted to neutron user
5.  check neutron service entity is created
6.  check endpoints for neutron are created
7.  check packages are installed
8.  check plugin.ini symbolic link is created
9.  check neutron servcie database is deployed
10. check openstack-nova-api service is running
11. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_neutron_controller:
  mariadb_pass: password            # root password of mariadb
  neutron_dbpass: password          # password of neutron database
  scripts_dir: /root/openrc_files   # location of openrc files
  domain: default                   # domain name of openstack environment
  neutron_pass: password            # password of neutron user
  region: RegionOne                 # region name of openstack environment
  controller: localhost             # hostname or ip of controller node
  rabbitmq_pass: password           # password of openstack user for rabbitmq
  nova_pass: password               # password of nova user
  provider_ifname: ens192           # name of interface for provider network
  overlayif_ip: 127.0.0.1           # ip with interface for overlay
  metadata_secret: password         # string for metadata secret
  keyfiles_dir: /var/suit_keyfiles  # location of keyfiles
```

## supported os
* CentOS 7
