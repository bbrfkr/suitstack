# Role Name: openstack_swift_proxy

## abstract
This role executes install and setting swift for proxy node.

## CAUTION!!
At the moment, this role only supported controller node as proxy node.

## procedures
1.  create swift user
2.  add admin role to swift user
3.  create swift service entity
4.  create endpoints for swift
5.  install packages
6.  put proxy-server.conf
7.  create base accout.builder file
8.  add each storage node to the account ring
9.  rebalance account ring
10. create base container.builder file
11. add each storage node to the container ring
12. rebalance container ring
13. create base object.builder file
14. add each storage node to the object ring
15. rebalance object ring
16. fetch rings to control machine
17. put swift.conf
18. ensure proper ownership of the config direcotory
19. enable and start proxy services

## tests (serverspec)
1.  check swift user is created
2.  check admin role is granted to swift user
3.  check swift service entities are created
4.  check endpoints for swift are created
5.  check packages are installed
6.  check account ring has information of all storage nodes
7.  check container ring has information of all storage nodes
8.  check object ring has information of all storage nodes
8.  check ownership of the config directory
10.  check proxy services are enabled and running

## tests (infrataster)
nothing

## parameters
```
---
openstack_swift_proxy:
  scripts_dir: /root/openrc_files                                # location of openrc files
  domain: default                                                # domain name of openstack environment
  swift_pass: password                                           # password of swift user
  region: RegionOne                                              # region name of openstack environment
  controller: localhost                                          # hostname or ip of controller node
  replica_count: 3                                               # number of copy of files managed by swift
  storage_nodes:
    - mgmt_ip: 192.168.0.10                                      # ip of management network for storage node
      devices:                                                   # list of devices managed by the storage node
        - "sdb"
        - "sdc"
        - "sdd"
  fetch_rings_dir: "Roles/openstack_swift_storage/itamae/files"  # location of controll machine  to fetch rings 
  hash_path_suffix: password                                     # suffix of hash path
  hash_path_prefix: password                                     # prefix of hash path
```

## supported os
* CentOS 7
