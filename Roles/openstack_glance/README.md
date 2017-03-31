# Role Name: openstack_glance

## abstract
This role executes install and setting glance.

## procedures
1.  create glance database
2.  grant privileges to access database
3.  create glance user
4.  add admin role to glance user
5.  create glance service entity
6.  create endpoints for glance
7.  install package
8.  edit config file
9.  create keyfiles dir
10. deploy glance service database
11. enable and start services

## tests (serverspec)
1.  check database is created
2.  check privileges of database is set
3.  check glance user is created
4.  check admin role is granted to glance user
5.  check glance service entity is created
6.  check endpoints for glance are created
7.  check package is installed
8.  check directory to store images is set
9.  check glance servcie database is deployed
10. check services are enabled and started

## tests (infrataster)
nothing

## parameters
```
---
openstack_glance:
  mariadb_pass: password                     # root user password of mariadb
  keyfiles_dir: /var/suit_keyfiles           # location of keyfiles
  glance_dbpass: password                    # password of glance database 
  scripts_dir: /root/openrc_files            # location of openrc files
  domain: default                            # domain name of openstack environment
  glance_pass: password                      # glance user password
  controller: localhost                      # hostname or ip of controller node
  region: RegionOne                          # region name of openstack environment
  store_images_dir: /var/lib/glance/images/  # directory path to store images
```

## supported os
* CentOS 7
