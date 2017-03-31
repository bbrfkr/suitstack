# Role Name: openstack_ntp

## abstract
This role executes ntp settings for openstack environment.

## procedures
1. install chrony
2. add entry ntp server to sync time
3. add entry of network to allow to sync time (when target is controller node)
4. enable and start chronyd

## tests (serverspec)
1. check chrony is installed
2. check chronyd service is running and enabled
3. check ntp servers are specified
4. check specified network is allowd to sync time
5. check target server's time is syncronized actually 

## tests (infrataster)
nothing

## parameters
```
---
openstack_ntp:
  ntp_servers:                       # entries of ntp servers wanted to sync time
    - server: 0.jp.pool.ntp.org
    - server: 1.jp.pool.ntp.org
    - server: 2.jp.pool.ntp.org
    - server: 3.jp.pool.ntp.org
  controller: localhost.localdomain  # controller node hostname or ip
  allow_sync:                        # networks allowed to sync time
    - network: 192.168.0.0/24
```

## supported os
* CentOS 7
