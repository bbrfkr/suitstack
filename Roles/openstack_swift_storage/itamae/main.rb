require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

swift_devs = node['openstack_swift_storage']['swift_devs']
mount_points_dir = node['openstack_swift_storage']['mount_points_dir']
mgmt_ip = node['openstack_swift_storage']['mgmt_ip']
hash_path_suffix = node['openstack_swift_storage']['hash_path_suffix']
hash_path_prefix = node['openstack_swift_storage']['hash_path_prefix']

# install xfsprogs and rsync
packages = ["xfsprogs", "rsync"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# create xfs file system w.r.t specified devices
swift_devs.each do |dev|
  execute "mkfs.xfs /dev/#{ dev }" do
    not_if "parted /dev/#{ dev } print | grep \"^ 1\" | grep \"xfs\""
  end
end

# create mount points
swift_devs.each do |dev|
  directory "#{ mount_points_dir }/#{ dev }" do
    action :create
  end
end

# edit fstab
swift_devs.each do |dev|
  file "/etc/fstab" do
    action :edit
    block do |content|
      setting = "\n/dev/#{ dev } #{ mount_points_dir }/#{ dev } xfs noatime,nodiratime,nobarrier,logbufs=8 0 2"
      if not (content =~ /#{ setting }/)
        content.concat(setting)
      end
    end
  end
end

# mount specified devices
swift_devs.each do |dev|
  execute "mount #{ mount_points_dir }/#{ dev }" do
    not_if "df | grep \"#{ mount_points_dir }/#{ dev }\""
  end
end

# edit rsyncd.conf
file "/etc/rsyncd.conf" do
  action :edit
  notifies :restart, "service[rsyncd]"
  block do |content|
    section = "### basic settings ###"
    settings = <<-"EOS"
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = #{ mgmt_ip }
    EOS

    if not (content =~ /#{ section }/)
      content.concat(section + "\n")
    end

    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_swift_storage, basic)", content)

    section = "[account]"
    settings = <<-"EOS"
max connections = 2
path = #{ mount_points_dir }/
read only = False
lock file = /var/lock/account.lock
    EOS
 
    if not (content =~ /#{ Regexp.escape(section) }/)
      content.concat(section + "\n")
    end
 
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_swift_storage, account)", content)

    section = "[container]"
    settings = <<-"EOS"
max connections = 2
path = #{ mount_points_dir }/
read only = False
lock file = /var/lock/container.lock
    EOS
 
    if not (content =~ /#{ Regexp.escape(section) }/)
      content.concat(section + "\n")
    end
 
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_swift_storage, container)", content)

    section = "[object]"
    settings = <<-"EOS"
max connections = 2
path = #{ mount_points_dir }/
read only = False
lock file = /var/lock/object.lock
    EOS
 
    if not (content =~ /#{ Regexp.escape(section) }/)
      content.concat(section + "\n")
    end
 
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_swift_storage, object)", content)
  end
end

# enable and start rsyncd service
service "rsyncd" do
  action [:enable, :start]
end

# install swift packages
packages = ["openstack-swift-account", "openstack-swift-container", \
            "openstack-swift-object"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# put swift config files 1
template "/etc/swift/account-server.conf" do
  action :create
  notifies :restart, "service[openstack-swift-account]"
  notifies :restart, "service[openstack-swift-account-auditor]"
  notifies :restart, "service[openstack-swift-account-reaper]"
  notifies :restart, "service[openstack-swift-account-replicator]"
  notifies :restart, "service[openstack-swift-container]"
  notifies :restart, "service[openstack-swift-container-auditor]"
  notifies :restart, "service[openstack-swift-container-replicator]"
  notifies :restart, "service[openstack-swift-container-updater]"
  notifies :restart, "service[openstack-swift-object]"
  notifies :restart, "service[openstack-swift-object-auditor]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  source "templates/account-server.conf.erb"
  mode "640"
  variables(mgmt_ip: mgmt_ip, \
            mount_points_dir: mount_points_dir)
end

template "/etc/swift/container-server.conf" do
  action :create
  notifies :restart, "service[openstack-swift-account]"
  notifies :restart, "service[openstack-swift-account-auditor]"
  notifies :restart, "service[openstack-swift-account-reaper]"
  notifies :restart, "service[openstack-swift-account-replicator]"
  notifies :restart, "service[openstack-swift-container]"
  notifies :restart, "service[openstack-swift-container-auditor]"
  notifies :restart, "service[openstack-swift-container-replicator]"
  notifies :restart, "service[openstack-swift-container-updater]"
  notifies :restart, "service[openstack-swift-object]"
  notifies :restart, "service[openstack-swift-object-auditor]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  source "templates/container-server.conf.erb"
  mode "640"
  variables(mgmt_ip: mgmt_ip, \
            mount_points_dir: mount_points_dir)
end

template "/etc/swift/object-server.conf" do
  action :create
  notifies :restart, "service[openstack-swift-account]"
  notifies :restart, "service[openstack-swift-account-auditor]"
  notifies :restart, "service[openstack-swift-account-reaper]"
  notifies :restart, "service[openstack-swift-account-replicator]"
  notifies :restart, "service[openstack-swift-container]"
  notifies :restart, "service[openstack-swift-container-auditor]"
  notifies :restart, "service[openstack-swift-container-replicator]"
  notifies :restart, "service[openstack-swift-container-updater]"
  notifies :restart, "service[openstack-swift-object]"
  notifies :restart, "service[openstack-swift-object-auditor]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  source "templates/object-server.conf.erb"
  mode "640"
  variables(mgmt_ip: mgmt_ip, \
            mount_points_dir: mount_points_dir)
end

# set owner to mount points directory
execute "chown -R swift:swift #{ mount_points_dir }" do
  only_if "(ls -ld #{ mount_points_dir } && ls -lR #{ mount_points_dir }) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v \"swift swift\""
end

# create recon directory 
directory "/var/cache/swift" do
  action :create
end

# set owner and permission to recon directory
execute "chown -R root:swift /var/cache/swift" do
  only_if "(ls -ld /var/cache/swift && ls -lR /var/cache/swift) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v \"root swift\""
end

execute "chmod -R 775 /var/cache/swift" do
  only_if "(ls -ld /var/cache/swift && ls -lR /var/cache/swift) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v -e \"[d|-]rwxrwxr-x\""
end

# put rings created by openstack-swift-proxy role
remote_file "/etc/swift/account.ring.gz" do
  action :create
  source "files/account.ring.gz"
  mode "644"
end

remote_file "/etc/swift/container.ring.gz" do
  action :create
  source "files/container.ring.gz"
  mode "644"
end

remote_file "/etc/swift/object.ring.gz" do
  action :create
  source "files/object.ring.gz"
  mode "644"
end

# put swift config files 2
template "/etc/swift/swift.conf" do
  action :create
  notifies :restart, "service[openstack-swift-account]"
  notifies :restart, "service[openstack-swift-account-auditor]"
  notifies :restart, "service[openstack-swift-account-reaper]"
  notifies :restart, "service[openstack-swift-account-replicator]"
  notifies :restart, "service[openstack-swift-container]"
  notifies :restart, "service[openstack-swift-container-auditor]"
  notifies :restart, "service[openstack-swift-container-replicator]"
  notifies :restart, "service[openstack-swift-container-updater]"
  notifies :restart, "service[openstack-swift-object]"
  notifies :restart, "service[openstack-swift-object-auditor]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  notifies :restart, "service[openstack-swift-object-replicator]"
  source "templates/swift.conf.erb"
  mode "640"
  variables(hash_path_suffix: hash_path_suffix, \
            hash_path_prefix: hash_path_prefix)
end

# ensure proper ownership of the config direcotory
execute "chown -R root:swift /etc/swift" do
  only_if "(ls -ld /etc/swift && ls -lR /etc/swift) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v \"root swift\""
end

# enable and start swift services
services = ["openstack-swift-account", "openstack-swift-account-auditor", \
            "openstack-swift-account-reaper", "openstack-swift-account-replicator", \
            "openstack-swift-container", "openstack-swift-container-auditor", \
            "openstack-swift-container-replicator", "openstack-swift-container-updater", \
            "openstack-swift-object", "openstack-swift-object-auditor", \
            "openstack-swift-object-replicator", "openstack-swift-object-updater"]

services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

