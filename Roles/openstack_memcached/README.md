# Role Name: openstack_memcached

## abstract
This role executes installing and setting memcached for openstack environment.

## procedures
1. install memcached packages
2. edit config file 
3. enable and start memcached

## tests (serverspec)
1. check memcached packages are installed
2. check listen address includes controller
3. check memcached service is running and enabled

## tests (infrataster)
nothing

## parameters
```
openstack_memcached:
  mgmt_ip: 127.0.0.1  # ip of management network
```

## supported os
* CentOS 7
