require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

# add compute nodes to cell database
execute "su -s /bin/sh -c \"nova-manage cell_v2 discover_hosts --verbose\" nova"

