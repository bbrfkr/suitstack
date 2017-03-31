# Role Name: openstack_heat

## abstract
This role executes install and setting heat for controller node.

## procedures
1.  create heat database
2.  grant privileges to access database
3.  create heat user
4.  add admin role to heat user
5.  create heat, heat-cfn service entities
6.  create endpoints for heat, heat-cfn
7.  create heat domain
8.  create heat_domain_admin user
9.  add admin role to heat_domain_admin user
10. create heat_stack_owner role
11. create heat_stack_user role
12. install package
13. edit config file
14. create keyfiles dir
15. deploy service database
16. enable and start services

## tests (serverspec)
1.  check heat database is created
2.  check privileges of database is set
3.  check heat user is created
4.  check admin role is granted to heat user
5.  check heat service entities are created
6.  check endpoints for heat are created
7.  check heat domain is created
8.  check heat_domain_admin user is created
9.  check admin role is granted to heat_domain_admin user
10. check heat_stack_owner and heat_stack_user roles are created
11. check package is installed
12. check heat servcie database is deployed
13. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_heat:
  mariadb_pass: password            # root password of mariadb
  heat_dbpass: password             # password of heat database
  scripts_dir: /root/openrc_files   # location of openrc files
  domain: default                   # domain name of openstack environment
  heat_pass: password               # password of heat user
  region: RegionOne                 # region name of openstack environment
  controller: localhost             # hostname or ip of controller node
  heat_domain_admin_pass: password  # password of heat_domain_admin user
  rabbitmq_pass: password           # password of openstack user for rabbitmq
  keyfiles_dir: /var/suit_keyfiles  # location of keyfiles
```

## supported os
* CentOS 7
