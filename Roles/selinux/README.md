# Role Name: selinux

## abstract
This role executes SELinux setting.  

## CAUTION!!
If SELinux status is changed, target will be rebooted.

## procedures
1. edit selinux setting
2. restore context of all files if SELinux status is changed to "Enforcing"

## tests (serverspec)
1. check selinux status is appropriate

## tests (infrataster)
nothing

## parameters
```
---
selinux:
  status: Enforcing   # selinux status ("Enforcing" or "Permissive" or "Disabled")
  reboot_waittime: 3  # time of waiting for server to be up
```

## supported os
* CentOS 7
