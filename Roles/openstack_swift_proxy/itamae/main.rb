require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

scripts_dir = node['openstack_swift_proxy']['scripts_dir']
domain = node['openstack_swift_proxy']['domain']
swift_pass = node['openstack_swift_proxy']['swift_pass']
region = node['openstack_swift_proxy']['region']
controller = node['openstack_swift_proxy']['controller']
replica_count = node['openstack_swift_proxy']['replica_count']
storage_nodes = node['openstack_swift_proxy']['storage_nodes']
fetch_rings_dir = node['openstack_swift_proxy']['fetch_rings_dir']
hash_path_suffix= node['openstack_swift_proxy']['hash_path_suffix']
hash_path_prefix = node['openstack_swift_proxy']['hash_path_prefix']

script = "source #{ scripts_dir }/admin-openrc &&"

# create swift user
execute "#{ script } openstack user create --domain #{ domain } --password #{ swift_pass } swift" do
  not_if "#{ script } openstack user list | grep swift"
end

# grant admin role to swift user
execute "#{ script } openstack role add --project service --user swift admin" do
  not_if "#{ script } openstack role list --project service --user swift | awk '{ print $4 }' | grep admin"
end

# create swift service entity
execute "#{ script } openstack service create --name swift --description \"OpenStack Object Storage\" object-store" do
  not_if "#{ script } openstack service list | grep \"swift\""
end

# create endpoints for swift
execute "#{ script } openstack endpoint create --region #{ region } object-store public http://#{ controller }:8080/v1/AUTH_%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep swift | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } object-store internal http://#{ controller }:8080/v1/AUTH_%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep swift | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } object-store admin http://#{ controller }:8080/v1" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep swift | grep admin"
end

# install packages
packages = ["openstack-swift-proxy", "python2-swiftclient", "python-keystoneclient", \
            "python-keystonemiddleware", "memcached"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# put config file 1
template "/etc/swift/proxy-server.conf" do
  action :create
  notifies :restart, "service[openstack-swift-proxy]"
  notifies :restart, "service[memcached]"
  source "templates/proxy-server.conf.erb"
  mode "640"
  variables(controller: controller, \
            domain: domain, \
            swift_pass: swift_pass)
end

# create base account.builder file
execute "cd /etc/swift && swift-ring-builder account.builder create 10 #{ replica_count } 1" do
  not_if "ls /etc/swift/account.builder"
end

# add each storage node to the account ring
storage_nodes.each do |str_node|
  str_node['devices'].each do |dev|
    cmd = <<-"EOS"
      cd /etc/swift && \\
      swift-ring-builder account.builder \\
      add --region 1 --zone 1 --ip #{ str_node['mgmt_ip'] } --port 6002 \\
      --device #{ dev } --weight 100
    EOS
    execute cmd do
      not_if "cd /etc/swift && swift-ring-builder account.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\""
    end
  end
end

# rebalance account ring
execute "cd /etc/swift && swift-ring-builder account.builder rebalance" do
  not_if "ls /etc/swift/account.ring.gz"
end

# create base container.builder file
execute "cd /etc/swift && swift-ring-builder container.builder create 10 #{ replica_count } 1" do
  not_if "ls /etc/swift/container.builder"
end

# add each storage node to the container ring
storage_nodes.each do |str_node|
  str_node['devices'].each do |dev|
    cmd = <<-"EOS"
      cd /etc/swift && \\
      swift-ring-builder container.builder \\
      add --region 1 --zone 1 --ip #{ str_node['mgmt_ip'] } --port 6001 \\
      --device #{ dev } --weight 100
    EOS
    execute cmd do
      not_if "cd /etc/swift && swift-ring-builder container.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\""
    end
  end
end

# rebalance container ring
execute "cd /etc/swift && swift-ring-builder container.builder rebalance" do
  not_if "ls /etc/swift/container.ring.gz"
end

# create base object.builder file
execute "cd /etc/swift && swift-ring-builder object.builder create 10 #{ replica_count } 1" do
  not_if "ls /etc/swift/object.builder"
end

# add each storage node to the object ring
storage_nodes.each do |str_node|
  str_node['devices'].each do |dev|
    cmd = <<-"EOS"
      cd /etc/swift && \\
      swift-ring-builder object.builder \\
      add --region 1 --zone 1 --ip #{ str_node['mgmt_ip'] } --port 6000 \\
      --device #{ dev } --weight 100
    EOS
    execute cmd do
      not_if "cd /etc/swift && swift-ring-builder object.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\""
    end
  end
end

# rebalance object ring
execute "cd /etc/swift && swift-ring-builder object.builder rebalance" do
  not_if "ls /etc/swift/object.ring.gz"
end

# fetch rings
local_ruby_block "fetch rings" do
  block do
    dl_files = ["account.ring.gz", "container.ring.gz", \
                "object.ring.gz"]
    dl_files.each do |dl_file|
      opt = { :port => ENV['CONN_PORT'] }
      if ENV['CONN_IDKEY'] != nil
        opt[:keys] = ["Env/" + ENV['CONN_IDKEY']]
      end
      if ENV['CONN_PASSPHRASE'] != nil
        opt[:passphrase] = ENV['CONN_PASSPHRASE']
      end
      if ENV['CONN_PASS'] != nil
        opt[:password] = ENV['CONN_PASS']
      end
      Net::SSH.start(ENV['CONN_HOST'], ENV['CONN_USER'], opt) do |ssh|
        ssh.scp.download!("/etc/swift/" + dl_file , fetch_rings_dir + "/" + dl_file)
      end 
      puts "\e[32mfetch file \"#{ "/etc/swift/" + dl_file }\" to \"#{ fetch_rings_dir+ "/" + dl_file }\"\e[0m"
    end    
  end
end

# put config file 2
template "/etc/swift/swift.conf" do
  action :create
  notifies :restart, "service[openstack-swift-proxy]"
  notifies :restart, "service[memcached]"
  source "templates/swift.conf.erb"
  mode "640"
  variables(hash_path_suffix: hash_path_suffix, \
            hash_path_prefix: hash_path_prefix)
end

# ensure proper ownership of the config direcotory
execute "chown -R root:swift /etc/swift" do
  only_if "(ls -ld /etc/swift && ls -lR /etc/swift) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v \"root swift\""
end

# enable and start proxy services
services = ["openstack-swift-proxy", "memcached"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

