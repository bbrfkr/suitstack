# Role Name: openstack_keystone_install

## abstract
This role executes install and setting keystone.

## procedures
1. create keystone database
2. grant privileges to access database
3. install packages
4. modify keystone config file
5. create keyfiles directory
6. deploy keystone service database
7. initialize fernet key
8. bootstrap identity service
9. modify and set apache config file
10. enable and start service of apache

## tests (serverspec)
1. check database is created
2. check privileges of database is set
3. check packages are installed
4. check keystone service database is deployed
5. check fernet key is initialized
6. check Identity service bootstrap is completed
7. check wsgi setting is set
8. check service is enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_keystone_install:
  mariadb_pass: password              # password for root user of mariadb
  keystone_dbpass: password           # keystone database password
  admin_pass: password                # admin user password
  controller: localhost               # hostname or ip of controller node
  keyfiles_dir: /var/suit_keyfiles    # location of keyfiles
  region: RegionOne                   # region name of openstack environment
```

## supported os
* CentOS 7
