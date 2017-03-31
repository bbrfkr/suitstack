require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

# install packages
packages = ["mongodb-server", "mongodb"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# modify config
file "/etc/mongod.conf" do
  action :edit
  block do |content|
    entry_bind_ip = "bind_ip = " + node['openstack_mongodb']['bind_ip']
    content.gsub!(/^bind_ip = .*$/, entry_bind_ip)
  end
  notifies :restart, "service[mongod]"
end

file "/etc/mongod.conf" do
  action :edit
  block do |content|
    marker = "# Use a smaller default file size (false by default)\n"
    entry_smallfiles = "smallfiles = " + (node['openstack_mongodb']['smallfiles'] ? "true\n" : "false\n")
    if not (content =~ /^#{ entry_smallfiles }/)
      content.gsub!(/^smallfiles = .*\n/, "")
      content.gsub!(marker, marker + entry_smallfiles)
    end
  end
  notifies :restart, "service[mongod]"
end

# enable and start service
service "mongod" do
  action [:enable, :start]
end

