# Role Name: yum_update

## abstract
This role executes yum update.  

## CAUTION!!
If at least one package is updated, target will be rebooted.

## procedures
1. execute yum update

## tests (serverspec)
1. check all packages are updated

## tests (infrataster)
nothing

## parameters
```
---
yum_update:
  reboot_waittime: 3  # time of waiting for server to be up 
```

## supported os
* CentOS 7
