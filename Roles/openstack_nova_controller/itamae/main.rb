require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_nova_controller']['mariadb_pass']
nova_dbpass = node['openstack_nova_controller']['novadb_pass']
scripts_dir = node['openstack_nova_controller']['scripts_dir']
nova_pass = node['openstack_nova_controller']['nova_pass']
domain = node['openstack_nova_controller']['domain']
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

# create nova user for openstack environment
execute "#{ script } openstack user create --domain #{ domain } --password #{ nova_pass } nova" do
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
execute "#{ script } openstack endpoint create --region #{ region } compute public http://#{ controller }:8774/v2.1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } compute internal http://#{ controller }:8774/v2.1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } compute admin http://#{ controller }:8774/v2.1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova | grep admin"
end

# install packages
packages = ["openstack-nova-api", "openstack-nova-conductor", \
            "openstack-nova-console", "openstack-nova-novncproxy", \
            "openstack-nova-scheduler"]
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
rpc_backend = rabbit
auth_strategy = keystone
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

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, oslo_messaging_rabbit)", content)

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = nova
password = #{ nova_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_controller, keystone_authtoken)", content)

    section = "[vnc]"
    settings = <<-"EOS"
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
  end
end

# create keyfiles directory
directory "#{ keyfiles_dir }/openstack_nova_controller" do
  action :create
end

# deploy nova_api and nova databases
execute "su -s /bin/sh -c \"nova-manage api_db sync\" nova && touch #{ keyfiles_dir }/openstack_nova_controller/api_db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_nova_controller/api_db_sync"
end

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

