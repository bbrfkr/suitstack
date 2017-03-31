require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mgmt_ip = node['openstack_nova_compute']['mgmt_ip']
controller = node['openstack_nova_compute']['controller']
rabbitmq_pass = node['openstack_nova_compute']['rabbitmq_pass']
domain = node['openstack_nova_compute']['domain']
nova_pass = node['openstack_nova_compute']['nova_pass']
console_keymap = node['openstack_nova_compute']['console_keymap']

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
rpc_backend = rabbit
auth_strategy = keystone
my_ip = #{ mgmt_ip }
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, DEFAULT)", content) 

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_nova_compute, oslo_messaging_rabbit)", content)

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

