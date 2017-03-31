# Role Name: openstack_mongodb

## abstract
This role executes installing and setting mongodb for openstack environment.

## procedures
1. install mongodb packages
2. modify config file
3. enable and start mongodb

## tests (serverspec)
1. check mongodb packages are installed
2. check mongod service is running and enabled
3. check specified bind_ip is set
4. check smallfiles switch is as specified 

## tests (infrataster)
nothing

## parameters
```
---
openstack_mongodb:
  bind_ip: 127.0.0.1  # listen address
  smallfiles: no      # use small journal file or not (yes or no)
```

## supported os
* CentOS 7
