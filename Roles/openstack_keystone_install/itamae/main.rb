require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_keystone_install']['mariadb_pass']
keystone_dbpass = node['openstack_keystone_install']['keystone_dbpass']
admin_pass = node['openstack_keystone_install']['admin_pass']
controller = node['openstack_keystone_install']['controller']
keyfiles_dir = node['openstack_keystone_install']['keyfiles_dir']
region = node['openstack_keystone_install']['region']

# create database
execute <<-"EOS" do
  mysql -uroot -p#{ mariadb_pass } -e "CREATE DATABASE keystone;"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show databases;" | grep keystone
  EOS
end

execute <<-"EOS" do
  mysql -uroot -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '#{ keystone_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'keystone'@'localhost'" | grep "ALL PRIVILEGES ON \\`keystone\\`.* TO 'keystone'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -uroot -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '#{ keystone_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'keystone'@'%'" | grep "ALL PRIVILEGES ON \\`keystone\\`.* TO 'keystone'@'%'"
  EOS
end

# install packages
packages = ["openstack-keystone", "httpd", "mod_wsgi"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# modify config file
file "/etc/keystone/keystone.conf" do
  action :edit
  notifies :restart, "service[httpd]"
  block do |content|
    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://keystone:#{ keystone_dbpass }@#{ controller }/keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_keystone_install, database)", content)
  end
end

file "/etc/keystone/keystone.conf" do
  action :edit
  notifies :restart, "service[httpd]"
  block do |content|
    section = "[token]"
    settings = <<-"EOS"
provider = fernet
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_keystone_install, token)", content)
  end
end

# create keyfiles dir
directory "#{ keyfiles_dir }/openstack_keystone_install" do
  action :create
end

# deploy keystone service database
execute "su -s /bin/sh -c \"keystone-manage db_sync\" keystone && touch #{ keyfiles_dir }/openstack_keystone_install/db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_keystone_install/db_sync"
end

# initialize fetnet key
execute "keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone && touch #{ keyfiles_dir }/openstack_keystone_install/fernet_setup" do
  not_if "ls #{ keyfiles_dir }/openstack_keystone_install/fernet_setup"
end

execute "keystone-manage credential_setup --keystone-user keystone --keystone-group keystone && touch #{ keyfiles_dir }/openstack_keystone_install/credential_setup" do
  not_if "ls #{ keyfiles_dir }/openstack_keystone_install/credential_setup"
end

# Bootstrap the Identity service
cmd = <<-"EOS"
  keystone-manage bootstrap --bootstrap-password #{ admin_pass } \\
    --bootstrap-admin-url http://#{ controller }:35357/v3/ \\
    --bootstrap-internal-url http://#{ controller }:5000/v3/ \\
    --bootstrap-public-url http://#{ controller }:5000/v3/ \\
    --bootstrap-region-id #{ region } && \\
  touch #{ keyfiles_dir }/openstack_keystone_install/bootstrap
EOS

execute cmd do
  not_if "ls #{ keyfiles_dir }/openstack_keystone_install/bootstrap"
end

# setting apache
file "/etc/httpd/conf/httpd.conf" do
  action :edit
  notifies :restart, "service[httpd]"
  block do |content|
    content.gsub!(/^#ServerName .*/, "ServerName #{ controller }")
    content.gsub!(/^ServerName .*/, "ServerName #{ controller }")
  end
end

link "/etc/httpd/conf.d/wsgi-keystone.conf" do
  to "/usr/share/keystone/wsgi-keystone.conf"
  action :create
  notifies :restart, "service[httpd]"
end

# enable and start apache
service "httpd" do
  action [:enable, :start]
end

