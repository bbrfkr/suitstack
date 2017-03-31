# Role Name: openstack_swift_storage

## abstract
This role executes install and setting swift for storage node.

## procedures
1.  install xfsprogs and rsync packages
2.  create xfs file system with specified devices
3.  create mount points
4.  edit fstab
5.  mount specified devices
6.  edit rsyncd.conf
7.  enable and start rsyncd service
8.  install swift packages
9.  put account-server.conf
10. put container-server.conf
11. put object-server.conf
12. set owner to mount points directory
13. create recon directory
14. set owner and permission to recon directory
15. put rings created by openstack-swift-proxy role
16. put swift.conf
17. ensure proper ownership of the config direcotory
18. enable and start swift services

## tests (serverspec)
1. check xfsprogs and rsync are installed
2. check sepcified devices are mounted
3. check rsyncd is enabled and running
4. check swift packages are installed
5. check owner of mount points directory is swift
6. check owner and permission to recon directory
7. check rings file exist
8. check ownership of the config directory
9. check swift services are enabled and running

## tests (infrataster)
nothing

## parameters
```
---
openstack_swift_storage:
  swift_devs:                    # list of devices managed by swift
    - "sdb"
  mount_points_dir: "/srv/node"  # directory of mount points managed by swift
  mgmt_ip: 127.0.0.1             # ip of management network for storage node
  hash_path_suffix: password     # suffix of hash path
  hash_path_prefix: password     # prefix of hash path
```

## supported os
* CentOS 7
