require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mgmt_ip = node['openstack_nova_compute']['mgmt_ip']
controller = node['openstack_nova_compute']['controller']
rabbitmq_pass = node['openstack_nova_compute']['rabbitmq_pass']
nova_pass = node['openstack_nova_compute']['nova_pass']
placement_pass = node['openstack_nova_compute']['placement_pass']
console_keymap = node['openstack_nova_compute']['console_keymap']
region = node['openstack_nova_compute']['region']

package "openstack-nova-compute" do
  action :install
end

hw_support = run_command("egrep -c '(vmx|svm)' /proc/cpuinfo", error: false).stdout.chomp

file "/etc/nova/nova.conf" do
  action :edit
  notifies :restart, "service[libvirtd]"
  notifies :restart, "service[openstack-nova-compute]"
  block do |content|
    section = "[DEFAULT]"
    settings = <<-"EOS"
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:#{ rabbitmq_pass }@#{ controller }
my_ip = #{ mgmt_ip }
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, DEFAULT)", content) 

    section = "[api]"
    settings = <<-"EOS"
auth_strategy = keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, api)", content) 

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
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, keystone_authtoken)", content)

    section = "[vnc]"
    settings = <<-"EOS"
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $my_ip
novncproxy_base_url = http://#{ controller }:6080/vnc_auto.html
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, vnc)", content)

    section = "[glance]"
    settings = <<-"EOS"
api_servers = http://#{ controller }:9292
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, glance)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/nova/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, oslo_concurrency)", content)

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
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, placement)", content)

    if hw_support == "0"
      section = "[libvirt]"
      settings = <<-"EOS"
virt_type = qemu
      EOS
      blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, libvirt)", content)
    else
      section = "[libvirt]"
      settings = "" 
      blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, libvirt)", content)
    end

    content.gsub!(/^#?keymap=.*$/, "keymap=#{ console_keymap }")
  end
end

services = ["libvirtd", "openstack-nova-compute"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

