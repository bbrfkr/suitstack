require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

controller = node['openstack_neutron_compute']['controller']
rabbitmq_pass = node['openstack_neutron_compute']['rabbitmq_pass']
domain = node['openstack_neutron_compute']['domain']
neutron_pass = node['openstack_neutron_compute']['neutron_pass']
provider_ifname = node['openstack_neutron_compute']['provider_ifname']
overlayif_ip = node['openstack_neutron_compute']['overlayif_ip']
region = node['openstack_neutron_compute']['region']

packages = ["openstack-neutron-linuxbridge", "ebtables", "ipset"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

file "/etc/neutron/neutron.conf" do
  action :edit
  notifies :restart, "service[neutron-linuxbridge-agent]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
rpc_backend = rabbit
auth_strategy = keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, DEFAULT)", content)

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, oslo_messaging_rabbit)", content)

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
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, keystone_authtoken)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/neutron/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, oslo_concurrency)", content)
  end
end

file "/etc/neutron/plugins/ml2/linuxbridge_agent.ini" do
  action :edit
  notifies :restart, "service[neutron-linuxbridge-agent]"
  block do |content|
    section = "[linux_bridge]"
    settings = <<-"EOS"
physical_interface_mappings = provider:#{ provider_ifname }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, linux_bridge)", content)

    section = "[vxlan]"
    settings = <<-"EOS"
enable_vxlan = True
local_ip = #{ overlayif_ip }
l2_population = True
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, vxlan)", content)

    section = "[securitygroup]"
    settings = <<-"EOS"
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, securitygroup)", content)
  end
end

file "/etc/nova/nova.conf" do
  action :edit
  notifies :restart, "service[openstack-nova-compute]", :immediately
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
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_neutron_compute, neutron)", content)
  end
end

# for restart openstack-nova-compute service
service "openstack-nova-compute"

service "neutron-linuxbridge-agent" do
  action [:enable, :start]
end
