require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

cinder_devices = node['openstack_cinder_storage']['cinder_devices']
cinder_vg = node['openstack_cinder_storage']['cinder_vg']
cinder_dbpass = node['openstack_cinder_storage']['cinder_dbpass']
controller = node['openstack_cinder_storage']['controller']
mgmt_ip = node['openstack_cinder_storage']['mgmt_ip']
rabbitmq_pass = node['openstack_cinder_storage']['rabbitmq_pass']
domain = node['openstack_cinder_storage']['domain']
cinder_pass = node['openstack_cinder_storage']['cinder_pass']

# install lvm package
package "lvm2" do
  action :install
end

# enable and start lvm2-lvmetad
service "lvm2-lvmetad" do
  action [:enable, :start]
end

# create physical volumes for cinder
cinder_devices.each do |dev|
  execute "pvcreate \"/dev/#{dev}\"" do
    not_if "pvs | grep /dev/#{dev}"
  end
end

# create volume group for cinder
cinder_devices_str = ""
cinder_devices.each do |dev|
  cinder_devices_str += "/dev/#{dev} "
end

execute "vgcreate #{ cinder_vg } #{ cinder_devices_str }" do
  not_if "vgs | grep \"#{ cinder_vg }\""
end

# extract device names of devices with operating system
root_dev = run_command("df | grep /$ | awk '{ print $1 }'").stdout.chomp
is_lvm = root_dev =~ /\/mapper\// ? true : false
root_devs = root_dev

if is_lvm
  root_dev.slice!("/dev/mapper/")
  vg = (root_dev[/.*-/])[0..-2]
  root_devs = run_command("pvs | grep #{ vg } | awk '{ print $1 }' | awk -F/ '{ print $3 }' | awk '{ sub(/[0-9]$/, \"\", $0) ; print $0 }'").stdout.chomp
end

root_devs = root_devs.split("\n").uniq

# edit lvm.conf
filter_devs = []

if is_lvm
  filter_devs = root_devs
end

cinder_devices.each do |dev|
  if dev =~ /[0-9]$/
    dev = dev[0,-2]
  end
  filter_devs.push(dev)
end

filter_devs_str = ""
filter_devs.each do |dev|
  filter_devs_str += "\"a/#{dev}/\", "
end

file "/etc/lvm/lvm.conf" do
  action :edit
  block do |content|
    if not (content =~ /^\s*filter = \[#{filter_devs_str}"r\/.*\/"\]\s*$/)
      content.sub!(/#?\s*filter = \[.*\]/, "filter = \[#{filter_devs_str}\"r/.*/\"\]")
    end
  end
end

# install cinder packages
packages = ["openstack-cinder", "targetcli", "python-keystone"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

file "/etc/cinder/cinder.conf" do
  action :edit
  notifies :restart, "service[openstack-cinder-volume]"
  notifies :restart, "service[target]"
  block do |content|
    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://cinder:#{ cinder_dbpass }@#{ controller }/cinder
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, database)", content)

    section = "[DEFAULT]"
    settings = <<-"EOS"
rpc_backend = rabbit
auth_strategy = keystone
my_ip = #{ mgmt_ip }
enabled_backends = lvm
glance_api_servers = http://#{ controller }:9292
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, DEFAULT)", content)

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, oslo_messaging_rabbit)", content)

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = cinder
password = #{ cinder_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, keystone_authtoken)", content)

    if not (content =~ /\[lvm\]/)
      content.concat("\n[lvm]\n")
    end

    section = "[lvm]"
    settings = <<-"EOS"
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = #{ cinder_vg }
iscsi_protocol = iscsi
iscsi_helper = lioadm
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, lvm)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/cinder/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_storage, oslo_concurrency)", content)
  end
end

services = ["openstack-cinder-volume", "target"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

