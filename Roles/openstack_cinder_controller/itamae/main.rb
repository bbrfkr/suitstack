require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_cinder_controller']['mariadb_pass']
cinder_dbpass = node['openstack_cinder_controller']['cinder_dbpass']
scripts_dir = node['openstack_cinder_controller']['scripts_dir']
cinder_pass = node['openstack_cinder_controller']['cinder_pass']
domain = node['openstack_cinder_controller']['domain']
region = node['openstack_cinder_controller']['region']
controller = node['openstack_cinder_controller']['controller']
mgmt_ip = node['openstack_cinder_controller']['mgmt_ip']
rabbitmq_pass = node['openstack_cinder_controller']['rabbitmq_pass']
keyfiles_dir = node['openstack_cinder_controller']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

# create cinder database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE cinder;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"cinder\""
end

# grant permissions to cinder database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '#{ cinder_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'cinder'@'localhost'" | grep "ALL PRIVILEGES ON \\`cinder\\`.* TO 'cinder'@'localhost'"  
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '#{ cinder_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'cinder'@'%'" | grep "ALL PRIVILEGES ON \\`cinder\\`.* TO 'cinder'@'%'"
  EOS
end

# create cinder user for openstack environment
execute "#{ script } openstack user create --domain #{ domain } --password #{ cinder_pass } cinder" do
  not_if "#{ script } openstack user list | grep cinder"
end

# grant admin role to cinder user
execute "#{ script } openstack role add --project service --user cinder admin" do
  not_if "#{ script } openstack role list --project service --user cinder | awk '{ print $4 }' | grep admin"
end

# create cinder, cinderv2 service entity
execute "#{ script } openstack service create --name cinder --description \"OpenStack Block Storage\" volume" do
  not_if "#{ script } openstack service list | grep -v \"cinderv2\" | grep \"cinder\""
end

execute "#{ script } openstack service create --name cinderv2 --description \"OpenStack Block Storage\" volumev2" do
  not_if "#{ script } openstack service list | grep \"cinderv2\""
end

# create endpoints for cinder, cinderv2
execute "#{ script } openstack endpoint create --region #{ region } volume public http://#{ controller }:8776/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinder | grep -v cinderv2 | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } volume internal http://#{ controller }:8776/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinder | grep -v cinderv2 | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } volume admin http://#{ controller }:8776/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinder | grep -v cinderv2 | grep admin"
end

execute "#{ script } openstack endpoint create --region #{ region } volumev2 public http://#{ controller }:8776/v2/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinderv2 | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } volumev2 internal http://#{ controller }:8776/v2/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinderv2 | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } volumev2 admin http://#{ controller }:8776/v2/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinderv2 | grep admin"
end

# install package
package "openstack-cinder" do
  action :install
end

# edit config file
file "/etc/cinder/cinder.conf" do
  action :edit
  notifies :restart, "service[openstack-cinder-api]"
  notifies :restart, "service[openstack-cinder-scheduler]"
  block do |content|
    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://cinder:#{ cinder_dbpass }@#{ controller }/cinder
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, database)", content)

    section = "[DEFAULT]"
    settings = <<-"EOS"
rpc_backend = rabbit
auth_strategy = keystone
my_ip = #{ mgmt_ip }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, DEFAULT)", content)

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, oslo_messaging_rabbit)", content)

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
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, keystone_authtoken)", content)

    section = "[oslo_concurrency]"
    settings = <<-"EOS"
lock_path = /var/lib/cinder/tmp
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, oslo_concurrency)", content)
  end
end

# create keyfiles directory
directory "#{ keyfiles_dir }/openstack_cinder_controller" do
  action :create
end

# deploy cinder database
execute "su -s /bin/sh -c \"cinder-manage db sync\" cinder && touch #{ keyfiles_dir }/openstack_cinder_controller/db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_cinder_controller/db_sync"
end

# edit config file with openstack-nova-api
file "/etc/nova/nova.conf" do
  action :edit
  notifies :restart, "service[openstack-nova-api]", :immediately
  block do |content|
    section = "[cinder]"
    settings = <<-"EOS"
os_region_name = #{ region }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_cinder_controller, cinder)", content)
  end
end

# for restarting openstack-nova-api service
service "openstack-nova-api"

# enable and start services
services = ["openstack-cinder-api", "openstack-cinder-scheduler"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

