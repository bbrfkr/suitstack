# Role Name: openstack_rabbitmq

## abstract
This role executes installing and setting rabbitmq for openstack environment.

## procedures
1. install rabbitmq package
2. enable and start rabbitmq
3. add openstack user
4. set permission for openstack user

## tests (serverspec)
1. check rabbitmq package are installed
2. check rabbitmq-server service is running and enabled
3. check openstack user exists
4. check permission for openstack user is set

## tests (infrataster)
nothing

## parameters
```
---
openstack_rabbitmq:
  rabbitmq_pass: password  # password for openstack user of rabbitmq
```

## supported os
* CentOS 7
