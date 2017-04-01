require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_nova_controller']['mariadb_pass']
nova_dbpass = node['openstack_nova_controller']['novadb_pass']
scripts_dir = node['openstack_nova_controller']['scripts_dir']
nova_pass = node['openstack_nova_controller']['nova_pass']
placement_pass = node['openstack_nova_controller']['placement_pass']
region = node['openstack_nova_controller']['region']
controller = node['openstack_nova_controller']['controller']
mgmt_ip = node['openstack_nova_controller']['mgmt_ip']
rabbitmq_pass = node['openstack_nova_controller']['rabbitmq_pass']
keyfiles_dir = node['openstack_nova_controller']['keyfiles_dir']
cpu_allocation_ratio = node['openstack_nova_controller']['cpu_allocation_ratio']
ram_allocation_ratio = node['openstack_nova_controller']['ram_allocation_ratio']

script = "source #{ scripts_dir }/admin-openrc &&"

# create nova_api database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE nova_api;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"nova_api\""
end

# create nova database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE nova;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"^nova$\""
end

# create nova_cell0 database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE novai_cell0;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"nova_cell0\""
end

# grant permissions to nova_api database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova'@'localhost'" | grep "ALL PRIVILEGES ON \\`nova_api\\`.* TO 'nova'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova'@'%'" | grep "ALL PRIVILEGES ON \\`nova_api\\`.* TO 'nova'@'%'"
  EOS
end

# grant permissions to nova database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova'@'localhost'" | grep "ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova'@'%'" | grep "ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'%'"
  EOS
end

# grant permissions to nova_cell0 database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova_cell0'@'localhost'" | grep "ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '#{ nova_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'nova_cell0'@'%'" | grep "ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'%'"
  EOS
end

# create nova user for openstack environment
execute "#{ script } openstack user create --domain default --password #{ nova_pass } nova" do
  not_if "#{ script } openstack user list | grep nova"
end

# grant admin role to nova user
execute "#{ script } openstack role add --project service --user nova admin" do
  not_if "#{ script } openstack role list --project service --user nova | awk '{ print $4 }' | grep admin"
end

# create nova service entity
execute "#{ script } openstack service create --name nova --description \"OpenStack Compute\" compute" do
  not_if "#{ script } openstack service list | grep nova"
end

# create endpoints for nova
execute "#{ script } openstack endpoint create --region #{ region } compute public http://#{ controller }:8774/v2.1" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } compute internal http://#{ controller }:8774/v2.1" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } compute admin http://#{ controller }:8774/v2.1" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep admin"
end

# create placement user for openstack environment
execute "#{ script } openstack user create --domain default --password #{ placement_pass } placement" do
  not_if "#{ script } openstack user list | grep placement"
end

# grant admin role to nova user
execute "#{ script } openstack role add --project service --user placement admin" do
  not_if "#{ script } openstack role list --project service --user placement | awk '{ print $4 }' | grep admian"
end

# create nova service entity
execute "#{ script } openstack service create --name placement --description \"Placement API\" placement" do
  not_if "#{ script } openstack service list | grep placement"
end

# create endpoints for nova
execute "#{ script } openstack endpoint create --region #{ region } placement public http://#{ controller }:8778" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep placement | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } placement internal http://#{ controller }:8778" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep placement | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } placement admin http://#{ controller }:8778" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep placement | grep admin"
end

# install packages
packages = ["openstack-nova-api", "openstack-nova-conductor", \
            "openstack-nova-console", "openstack-nova-novncproxy", \
            "openstack-nova-scheduler", "openstack-nova-placement-api"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# modify config file
file "/etc/nova/nova.conf" do
  action :edit
  notifies :restart, "service[openstack-nova-api]"
  notifies :restart, "service[openstack-nova-consoleauth]"
  notifies :restart, "service[openstack-nova-scheduler]"
  notifies :restart, "service[openstack-nova-conductor]"
  notifies :restart, "service[openstack-nova-novncproxy]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:#{ rabbitmq_pass }@#{ controller }
my_ip = #{ mgmt_ip }
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
cpu_allocation_ratio = #{ cpu_allocation_ratio }
ram_allocation_ratio = #{ ram_allocation_ratio }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, DEFAULT)", content)

    section = "[api_database]"
    settings = <<-"EOS"
connection = mysql+pymysql://nova:#{ nova_dbpass }@#{ controller }/nova_api
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, api_database)", content)

    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://nova:#{ nova_dbpass }@#{ controller }/nova
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, database)", content)

    section = "[api]"
    settings = <<-"EOS"
auth_strategy = keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, api)", content)

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = #{ nova_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, keystone_authtoken)", content)

    section = "[vnc]"
    settings = <<-"EOS"
enabled = true
vncserver_listen = $my_ip
vncserver_proxyclient_address = $my_ip
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, vnc)", content)

    section = "[glance]"
    settings = <<-"EOS"
api_servers = http://#{ controller }:9292
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, glance)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/nova/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, oslo_concurrency)", content)

    section = "[placement]"
    settings = <<-"EOS"
os_region_name = #{ region }
project_domain_name = default
project_name = service
auth_type = password
user_domain_name = default
auth_url = http://#{ controller }:35357/v3
username = placement
password = #{ placement_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, placement)", content)
  end
end

# supply bug fix to enable access to the placement api
remote_file "/etc/httpd/conf.d/00-nova-placement-api.conf" do
  action :create 
end

# create keyfiles directory
directory "#{ keyfiles_dir }/openstack_nova_controller" do
  action :create
end

# deploy nova_api databases
execute "su -s /bin/sh -c \"nova-manage api_db sync\" nova && touch #{ keyfiles_dir }/openstack_nova_controller/api_db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_nova_controller/api_db_sync"
end

# register the cell0 database
execute "su -s /bin/sh -c \"nova-manage cell_v2 map_cell0\" nova && touch #{ keyfiles_dir }/openstack_nova_controller/map_cell0" do
  not_if "ls #{ keyfiles_dir }/openstack_nova_controller/map_cell0"
end

# create the cell1 cell
execute "su -s /bin/sh -c \"nova-manage cell_v2 create_cell --name=cell1 --verbose\" nova && touch #{ keyfiles_dir }/openstack_nova_controller/create_cell" do
  not_if "ls #{ keyfiles_dir }/openstack_nova_controller/create_cell"
end

# deploy nova databases
execute "su -s /bin/sh -c \"nova-manage db sync\" nova && touch #{ keyfiles_dir }/openstack_nova_controller/db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_nova_controller/db_sync"
end

# enable and start services of nova
services = ["openstack-nova-api", "openstack-nova-consoleauth", \
            "openstack-nova-scheduler", "openstack-nova-conductor", \
            "openstack-nova-novncproxy"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

