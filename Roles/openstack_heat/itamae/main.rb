require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = node['openstack_heat']['mariadb_pass']
heat_dbpass = node['openstack_heat']['heat_dbpass']
scripts_dir = node['openstack_heat']['scripts_dir']
domain = node['openstack_heat']['domain']
heat_pass = node['openstack_heat']['heat_pass']
region = node['openstack_heat']['region']
controller = node['openstack_heat']['controller']
heat_domain_admin_pass = node['openstack_heat']['heat_domain_admin_pass']
rabbitmq_pass = node['openstack_heat']['rabbitmq_pass']
keyfiles_dir = node['openstack_heat']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

# create heat database
execute "mysql -u root -p#{ mariadb_pass } -e \"CREATE DATABASE heat;\"" do
  not_if "mysql -u root -p#{ mariadb_pass } -e \"show databases;\" | grep \"heat\""
end

# grant permissions to heat database
execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '#{ heat_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'heat'@'localhost'" | grep "ALL PRIVILEGES ON \\`heat\\`.* TO 'heat'@'localhost'"
  EOS
end

execute <<-"EOS" do
  mysql -u root -p#{ mariadb_pass } -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '#{ heat_dbpass }';"
EOS
  not_if <<-"EOS"
    mysql -uroot -p#{ mariadb_pass } -e "show grants for 'heat'@'%'" | grep "ALL PRIVILEGES ON \\`heat\\`.* TO 'heat'@'%'"
  EOS
end

# create heat user for openstack environment
execute "#{ script } openstack user create --domain #{ domain } --password #{ heat_pass } heat" do
  not_if "#{ script } openstack user list | grep -v \"heat_domain_admin\" | grep heat"
end

# grant admin role to heat user
execute "#{ script } openstack role add --project service --user heat admin" do
  not_if "#{ script } openstack role list --project service --user heat | awk '{ print $4 }' | grep admin"
end

# create heat, heat-cfn service entities
execute "#{ script } openstack service create --name heat --description \"Orchestration\" orchestration" do
  not_if "#{ script } openstack service list | grep -v \"heat-cfn\" | grep \"heat\""
end

execute "#{ script } openstack service create --name heat-cfn --description \"Orchestration\"  cloudformation" do
  not_if "#{ script } openstack service list | grep \"heat-cfn\""
end

# create endpoints for heat, heat-cfn service entities
execute "#{ script } openstack endpoint create --region #{ region } orchestration public http://#{ controller }:8004/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | grep heat | grep -v heat-cfn | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } orchestration internal http://#{ controller }:8004/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | grep heat | grep -v heat-cfn | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } orchestration admin http://#{ controller }:8004/v1/%\\(tenant_id\\)s" do
  not_if "#{ script } openstack endpoint list | grep heat | grep -v heat-cfn | grep admin"
end

execute "#{ script } openstack endpoint create --region #{ region } cloudformation public http://#{ controller }:8000/v1" do
  not_if "#{ script } openstack endpoint list | grep heat-cfn | grep public"
end

execute "#{ script } openstack endpoint create --region #{ region } cloudformation internal http://#{ controller }:8000/v1" do
  not_if "#{ script } openstack endpoint list | grep heat-cfn | grep internal"
end

execute "#{ script } openstack endpoint create --region #{ region } cloudformation admin http://#{ controller }:8000/v1" do
  not_if "#{ script } openstack endpoint list | grep heat-cfn | grep admin"
end

# create heat domain
execute "#{ script } openstack domain create --description \"Stack projects and users\" heat" do
  not_if "#{ script } openstack domain list | awk '{ print $4 }' | grep heat"
end

# create heat_domain_admin user
execute "#{ script } openstack user create --domain heat --password #{ heat_domain_admin_pass } heat_domain_admin" do
  not_if "#{ script } openstack user list --domain heat | grep heat_domain_admin"
end

# grant admin role to heat_domain_admin
execute "#{ script } openstack role add --domain heat --user-domain heat --user heat_domain_admin admin" do
  not_if "#{ script } openstack role list --domain heat --user-domain heat --user heat_domain_admin | grep admin"
end

# create heat_stack_owner role
execute "#{ script } openstack role create heat_stack_owner" do
  not_if "#{ script } openstack role list | grep heat_stack_owner"
end

# create heat_stack_user role
execute "#{ script } openstack role create heat_stack_user" do
  not_if "#{ script } openstack role list | grep heat_stack_user"
end

# install packages
packages = ["openstack-heat-api", "openstack-heat-api-cfn", "openstack-heat-engine"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# edit config file
file "/etc/heat/heat.conf" do
  action :edit
  notifies :restart, "service[openstack-heat-api]"
  notifies :restart, "service[openstack-heat-api-cfn]"
  notifies :restart, "service[openstack-heat-engine]"
  block do |content|
    section = "[database]"
    settings = <<-"EOS"
connection = mysql+pymysql://heat:#{ heat_dbpass }@#{ controller }/heat
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, database)", content)

    section = "[DEFAULT]"
    settings = <<-"EOS"
rpc_backend = rabbit
heat_metadata_server_url = http://#{ controller }:8000
heat_waitcondition_server_url = http://#{ controller }:8000/v1/waitcondition
stack_domain_admin = heat_domain_admin
stack_domain_admin_password = #{ heat_domain_admin_pass }
stack_user_domain_name = heat
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, DEFAULT)", content)

    section = "[oslo_messaging_rabbit]"
    settings = <<-"EOS"
rabbit_host = #{ controller }
rabbit_userid = openstack
rabbit_password = #{ rabbitmq_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heatr, oslo_messaging_rabbit)", content)

    if content !~ /\[keystone_authtoken\]/
      content.concat("\n[keystone_authtoken]\n")
    end

    section = "[keystone_authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
auth_url = http://#{ controller }:35357
memcached_servers = #{ controller }:11211
auth_type = password
project_domain_name = #{ domain }
user_domain_name = #{ domain }
project_name = service
username = heat
password = #{ heat_pass }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, keystone_authtoken)", content)

    section = "[trustee]"
    settings = <<-"EOS"
uth_plugin = password
auth_url = http://#{ controller }:35357
username = heat
password = #{ heat_pass }
user_domain_name = #{ domain }
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, trustee)", content)

    section = "[clients_keystone]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:35357
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, clients_keystone)", content)

    section = "[ec2authtoken]"
    settings = <<-"EOS"
auth_uri = http://#{ controller }:5000
    EOS
    blockinfile(section, settings, "MANAGED BY ITAMAE (openstack_heat, ec2authtoken)", content)
  end
end

# create keyfiles directory
directory "#{ keyfiles_dir }/openstack_heat" do
  action :create
end

# deploy heat database
execute "su -s /bin/sh -c \"heat-manage db_sync\" heat && touch #{ keyfiles_dir }/openstack_heat/db_sync" do
  not_if "ls #{ keyfiles_dir }/openstack_heat/db_sync"
end

# enable and start services
services = ["openstack-heat-api", "openstack-heat-api-cfn", "openstack-heat-engine"]
services.each do |srv|
  service srv do
    action [:enable, :start]
  end
end

