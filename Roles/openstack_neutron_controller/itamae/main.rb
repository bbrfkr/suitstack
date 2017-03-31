require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_neutron_controller']['mariadb_pass']
neutron_dbpass = node['openstack_neutron_controller']['neutron_dbpass']
scripts_dir = node['openstack_neutron_controller']['scripts_dir']
domain = node['openstack_neutron_controller']['domain']
neutron_pass = node['openstack_neutron_controller']['neutron_pass']
region = node['openstack_neutron_controller']['region']
controller = node['openstack_neutron_controller']['controller']
rabbitmq_pass = node['openstack_neutron_controller']['rabbitmq_pass']
nova_pass = node['openstack_neutron_controller']['nova_pass']
provider_ifname = node['openstack_neutron_controller']['provider_ifname']
overlayif_ip = node['openstack_neutron_controller']['overlayif_ip']
metadata_secret = node['openstack_neutron_controller']['metadata_secret']
keyfiles_dir = node['openstack_neutron_controller']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

# create neutron database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE neutron;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"neutron\""
end

# grant permissions to neutron database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '#{ neutron_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'neutron'@'localhost'" | grep "ALL PRIVILEGES ON \\`neutron\\`.* TO 'neutron'@'localhost'"  
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '#{ neutron_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'neutron'@'%'" | grep "ALL PRIVILEGES ON \\`neutron\\`.* TO 'neutron'@'%'"
  EOS
end

# create neutron user for openstack environment
execute "#{ script } openstack user create --domain #{ domain } --password #{ neutron_pass } neutron" do
  not_if "#{ script } openstack user list | grep neutron"
end

# grant admin role to nova user
execute "#{ script } openstack role add --project service --user neutron admin" do
  not_if "#{ script } openstack role list --project service --user neutron | awk '{ print $4 }' | grep admin"
end

# create neutron service entity
execute "#{ script } openstack service create --name neutron --description \"OpenStack Networking\" network" do
  not_if "#{ script } openstack service list | grep neutron"
end

# create endpoints for neutron
execute "#{ script } openstack endpoint create --region #{ region } network public http://#{ controller }:9696" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep neutron | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } network internal http://#{ controller }:9696" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep neutron | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } network admin http://#{ controller }:9696" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep neutron | grep admin"
end

# install packages
packages = ["openstack-neutron", "openstack-neutron-ml2", \
            "openstack-neutron-linuxbridge", "ebtables"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# modify config file
file "/etc/neutron/neutron.conf" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://neutron:#{ neutron_dbpass }@#{ controller }/neutron
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, database)", content)

    section = "[DEFAULT]"
    settings = <<-"EOS"
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, DEFAULT)", content)

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, oslo_messaging_rabbit)", content)

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = neutron
password = #{ neutron_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, keystone_authtoken)", content)

    section = "[nova]"
    settings = <<-"EOS"
auth_url = http://#{ controller }:35357
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
region_name = #{ region }
project_name = service
username = nova
password = #{ nova_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, nova)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/neutron/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, oslo_concurrency)", content)
  end
end

file "/etc/neutron/plugins/ml2/ml2_conf.ini" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[ml2]"
    settings = <<-"EOS"
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, ml2)", content)

    section = "[ml2_type_flat]"
    settings = <<-"EOS"
flat_networks = provider
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, ml2_type_flat)", content)

    section = "[ml2_type_vxlan]"
    settings = <<-"EOS"
vni_ranges = 1:1000
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, ml2_type_vxlan)", content)

    section = "[securitygroup]"
    settings = <<-"EOS"
enable_ipset = True
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, securitygroup)", content)
  end
end

file "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[linux_bridge]"
    settings = <<-"EOS"
physical_interface_mappings = provider:#{ provider_ifname }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, linux_bridge)", content)

    section = "[vxlan]"
    settings = <<-"EOS"
enable_vxlan = True
local_ip = #{ overlayif_ip }
l2_population = True
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, vxlan)", content)

    section = "[securitygroup]"
    settings = <<-"EOS"
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, securitygroup)", content)
  end
end

file "/etc/neutron/l3_agent.ini" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
external_network_bridge =
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, DEFAULT)", content)
  end
end

file "/etc/neutron/dhcp_agent.ini" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, DEFAULT)", content)
  end
end

file "/etc/neutron/metadata_agent.ini" do
  action :edit
  notifies :restart, "service[neutron-server]"
  notifies :restart, "service[neutron-linuxbridge-agent]"
  notifies :restart, "service[neutron-dhcp-agent]"
  notifies :restart, "service[neutron-metadata-agent]"
  notifies :restart, "service[neutron-l3-agent]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
nova_metadata_ip = #{ controller }
metadata_proxy_shared_secret = #{ metadata_secret }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, DEFAULT)", content)
  end
end

file "/etc/nova/nova.conf" do
  action :edit
  notifies :restart, "service[openstack-nova-api]", :immediately
  block do |content|
    section = "[neutron]"
    settings = <<-"EOS"
url = http://#{ controller }:9696
auth_url = http://#{ controller }:35357
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
region_name = #{ region }
project_name = service
username = neutron
password = #{ neutron_pass }
service_metadata_proxy = True
metadata_proxy_shared_secret = #{ metadata_secret }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_controller, neutron)", content)
  end
end

# create keyfiles directory
directory "#{ keyfiles_dir }/openstack_neutron_controller" do
  action :create
end

# create plugin.ini symbolic link
link "/etc/neutron/plugin.ini" do
  to "/etc/neutron/plugins/ml2/ml2_conf.ini"
end

# deploy neutron database
execute "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" neutron && touch #{ keyfiles_dir }/openstack_neutron_controller/neutron_db_manage" do
  not_if "ls #{ keyfiles_dir }/openstack_neutron_controller/neutron_db_manage"
end

# for restarting openstack-nova-api service
service "openstack-nova-api"

# enable and start services
services = ["neutron-server", "neutron-linuxbridge-agent", \
            "neutron-dhcp-agent", "neutron-metadata-agent", \
            "neutron-l3-agent"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

