# Role Name: openstack_mariadb

## abstract
This role executes installing and setting mariadb for openstack environment.

## procedures
1. install mariadb packages
2. set config file
3. enable and start mariadb
4. execute mysql_secure_installation

## tests (serverspec)
1. check packages are installed
2. check mariadb service is running and enabled
3. check specified bind-address is set

## tests (infrataster)
nothing

## parameters
```
---
openstack_mariadb:
  bind_address: 127.0.0.1          # listen address
  tmp_dir: /tmp/openstack_mariadb  # tmp dir used by this role
  mariadb_pass: password           # root user password
```

## supported os
* CentOS 7
