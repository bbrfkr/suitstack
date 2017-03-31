# Role Name: suit_keyfiles

## abstract
This role executes creating keyfile's directory for suit. Keyfile is used to tell a procedure ended to suit.

## procedures
1. create keyfile's directory

## tests (serverspec)
1. check directory for keyfile's is created

## tests (infrataster)
nothing

## parameters
```
---
suit_keyfiles:
  keyfiles_dir: /var/suit_keyfiles  # directory of keyfile's
```

## supported os
* CentOS 7
