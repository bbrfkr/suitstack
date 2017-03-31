require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_glance']['mariadb_pass']
keyfiles_dir = node['openstack_glance']['keyfiles_dir']
glance_dbpass = node['openstack_glance']['glance_dbpass']
scripts_dir = node['openstack_glance']['scripts_dir']
domain = node['openstack_glance']['domain']
glance_pass = node['openstack_glance']['glance_pass']
controller = node['openstack_glance']['controller']
region = node['openstack_glance']['region']
store_images_dir = node['openstack_glance']['store_images_dir']

scripts = "source #{ scripts_dir }/admin-openrc &&"

# create glance database
execute "mysql -uroot -p#{ mariadb_pass } -e \"CREATE DATABASE glance;\"" do
  not_if "mysql -uroot -p#{ mariadb_pass } -e \"show databases\" | grep glance"
end

# grant permissions to glance database
execute <<-"EOS" do
  mysql -uroot -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost'IDENTIFIED BY '#{ glance_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'glance'@'localhost'" | grep "ALL PRIVILEGES ON \\`glance\\`.* TO 'glance'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -uroot -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '#{ glance_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'glance'@'%'" | grep "ALL PRIVILEGES ON \\`glance\\`.* TO 'glance'@'%'"
  EOS
end

# create glance user
execute "#{ scripts } openstack user create --domain #{ domain } --password #{ glance_pass } glance" do 
  not_if "#{ scripts } openstack user list | grep glance"
end

# add admin role to glance user
execute "#{ scripts } openstack role add --project service --user glance admin" do
  not_if "#{ scripts } openstack role list --project service --user glance | awk '{ print $4 }' | grep admin"
end

# create glance service entity
execute "#{ scripts } openstack service create --name glance --description \"OpenStack Image\" image" do
  not_if "#{ scripts } openstack service list | grep glance"
end

# create endpoints for glance
execute "#{ scripts } openstack endpoint create --region #{ region } image public http://#{ controller }:9292" do
  not_if "#{ scripts } openstack endpoint list | awk '{ print $6, $12 }' | grep glance | grep public"
end

execute "#{ scripts } openstack endpoint create --region #{ region } image internal http://#{ controller }:9292" do
  not_if "#{ scripts } openstack endpoint list | awk '{ print $6, $12 }' | grep glance | grep internal"
end

execute "#{ scripts } openstack endpoint create --region #{ region } image admin http://#{ controller }:9292" do
  not_if "#{ scripts } openstack endpoint list | awk '{ print $6, $12 }' | grep glance | grep admin"
end

# package install
package "openstack-glance" do
  action :install
end

# create directory to store images
directory "#{ store_images_dir }" do
  mode "750"
  owner "glance"
  group "glance"
end

# edit config file
file "/etc/glance/glance-api.conf" do
  action :edit
  notifies :restart, "service[openstack-glance-api]"
  notifies :restart, "service[openstack-glance-registry]"
  block do |content|
    section = "[database]" 
    settings = <<-"EOS"
connection = mysql+pymysql://glance:#{ glance_dbpass }@#{ controller }/glance
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, database)", content)

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = glance
password = #{ glance_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, keystone_authtoken)", content)

    section = "[paste_deploy]"
    settings = <<-"EOS"
flavor = keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, paste_deploy)", content)

    section = "[glance_store]"
    settings = <<-"EOS"
stores = file,http
default_store = file
filesystem_store_datadir = #{ store_images_dir }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, glance_store)", content)
  end
end

file "/etc/glance/glance-registry.conf" do
  action :edit
  notifies :restart, "service[openstack-glance-api]"
  notifies :restart, "service[openstack-glance-registry]"
  block do |content|
    section = "[database]" 
    settings = <<-"EOS"
connection = mysql+pymysql://glance:#{ glance_dbpass }@#{ controller }/glance
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, database)", content)

    section = "[keystone_authtoken]" 
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = glance
password = #{ glance_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, keystone_authtoken)", content)

    section = "[paste_deploy]" 
    settings = <<-"EOS"
flavor = keystone
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_glance, paste_deploy)", content)
  end
end

# create keyfiles dir
directory "#{ keyfiles_dir }/openstack_glance" do
  action :create
end

# deploy glance service database
execute "su -s /bin/sh -c \"glance-manage db_sync\" glance && touch #{ keyfiles_dir }/openstack_glance/db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_glance/db_sync"
end

# enable and start services
services = ["openstack-glance-api","openstack-glance-registry"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

