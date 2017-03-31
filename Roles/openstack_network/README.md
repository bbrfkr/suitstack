# Role Name: openstack_network

## abstract
This role executes basic network setting for openstack environment.  

## CAUTION!!
If at least one change of the following changes occurs, target will be rebooted.
* Hostname is changed
* SELinux state is changed

## procedures
1. disable NetworkManager
2. disable firewalld
3. disable SELinux
4. set hostname (hook reboot)
5. edit hosts
6. edit resolv.conf
7. disable PEERDNS

## tests (serverspec)
1. check NetworkManger and firewalld are disabled and stopped
2. check SELinux is disabled
3. check hostname
4. check hosts entries are available
5. check dns servers are set
6. check be able to access internet

## tests (infrataster)
nothing

## parameters
```
---
openstack_network:
  hostname: localhost.localdomain                                                   # hostname
  hosts_entries:
    - server: 'localhost localhost.localdomain localhost4 localhost4.localdomain4'  # name of server
      ip: '127.0.0.1'                                                               # address of server
    - server: 'localhost6 localhost6.localdomain6'                                  # name of server
      ip: '::1'                                                                     # address of server
  dns_servers:
    - server: 8.8.8.8                                                               # address of dns server
    - server: 8.8.4.4                                                               # address of dns server
  reboot_waittime: 3                                                                # time of waiting for server to be up 

```

## supported os
* CentOS 7
