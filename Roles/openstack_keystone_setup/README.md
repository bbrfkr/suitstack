# Role Name: openstack_keystone_install

## abstract
This role executes install and setting keystone.

## CAUTION!!
This role doesn't preserve idempotence.

## procedures
1.  create keystone service entity
2.  create endpoints for keystone
3.  create domain for openstack environment
4.  create admin project
5.  create admin user
6.  create admin role
7.  add admin role to admin user
8.  create service project
9.  create demo project
10. create demo user
11. create user role
12. add user role to demo user
13. disable temporary authentication token mechanism
14. create directory for openrc files
15. create openrc files

## tests (serverspec)
1.  check service entity exists 
2.  check endpoints are created
3.  check domain is created
4.  check admin, demo and service projects are created
5.  check admin and demo users are created
6.  check admin and user roles are created
7.  check admin role is granted to admin user 
8.  check user role is granted to demo user
9.  check temporary authentication token mechanisim is disabled
10. check openrc files is set

## tests (infrataster)
nothing

## parameters
```
openstack_keystone_setup:
  admin_token: password            # temporary authentication token
  controller: localhost            # hostname or ip of controller node
  region: RegionOne                # region name for openstack environment
  domain: default                  # domain name for openstack environment
  admin_pass: password             # admin user's password for openstack environment
  demo_pass: password              # demo user's password for openstack environment
  scripts_dir: /root/openrc_files  # location of openrc files
```

## supported os
* CentOS 7
