#!/bin/sh
if [ $# -ne 1 ] ; then
  echo "ERROR: invalid number of arguments"
  exit 1
else
  if [ "$1" = "exec" ] ; then
    rake -f .Rakefile_serverspec spec
  else
    echo "ERROR: '$1' is invalid subcommand"
    exit 1
  fi
fi



