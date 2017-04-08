require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

# install packages
packages = ["memcached", "python-memcached"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# edit config
file "/etc/sysconfig/memcached" do
  action :edit
  notifies :restart, "service[memcached]"
  block do |content|
    content.gsub!(/^OPTIONS="-l .*"$/, "OPTIONS=\"-l 127.0.0.1,#{ node['openstack_memcached']['mgmt_ip'] },::1\"")
  end
end

# enable and start service
service "memcached" do
  action [:enable, :start]
end

