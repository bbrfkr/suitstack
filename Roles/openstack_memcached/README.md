# Role Name: openstack_memcached

## abstract
This role executes installing and setting memcached for openstack environment.

## procedures
1. install memcached packages
2. edit config file 
3. enable and start memcached

## tests (serverspec)
1. check memcached packages are installed
2. check listen address is any address
3. check memcached service is running and enabled

## tests (infrataster)
nothing

## parameters
nothing

## supported os
* CentOS 7
