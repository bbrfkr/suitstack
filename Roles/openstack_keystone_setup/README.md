# Role Name: openstack_keystone_install

## abstract
This role executes install and setting keystone.

## CAUTION!!
This role doesn't preserve idempotence.

## procedures
1. create directory for openrc files
2. create openrc files
3. create service project
4. create demo project
5. create demo user
6. create user role
7. add user role to demo user
8. disable temporary authentication token mechanism

## tests (serverspec)
1.  check service projects are created
2.  check user roles are created
3.  check temporary authentication token mechanisim is disabled
4.  check openrc files is set

## tests (infrataster)
nothing

## parameters
```
openstack_keystone_setup:
  admin_token: password            # temporary authentication token
  controller: localhost            # hostname or ip of controller node
  region: RegionOne                # region name for openstack environment
  admin_pass: password             # admin user's password for openstack environment
  demo_pass: password              # demo user's password for openstack environment
  scripts_dir: /root/openrc_files  # location of openrc files
```

## supported os
* CentOS 7
