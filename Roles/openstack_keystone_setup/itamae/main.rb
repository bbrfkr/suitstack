require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

admin_token = node['openstack_keystone_setup']['admin_token']
controller = node['openstack_keystone_setup']['controller']
region = node['openstack_keystone_setup']['region']
admin_pass = node['openstack_keystone_setup']['admin_pass']
demo_pass = node['openstack_keystone_setup']['demo_pass']
scripts_dir = node['openstack_keystone_setup']['scripts_dir']

envs = "source #{ scripts_dir }/admin-openrc &&"

# create directory for openrc files
directory scripts_dir do
  action :create
end

# create openrc files
template "#{ scripts_dir }/admin-openrc" do
  action :create
  variables(admin_pass: admin_pass, \
            controller: controller )
end

template "#{ scripts_dir }/demo-openrc" do
  action :create
  variables(demo_pass: demo_pass, \
            controller: controller )
end

# create service project
execute "#{ envs } openstack project create --domain default --description \"Service Project\" service" do
  not_if "#{ envs } openstack project list | grep service"
end

# create demo project
execute "#{ envs } openstack project create --domain default --description \"Demo Project\" demo" do
  not_if "#{ envs } openstack project list | grep demo"
end

# create demo user
execute "#{ envs } openstack user create --domain default --password #{ demo_pass } demo" do
  not_if "#{ envs } openstack user list | grep demo"
end

# create user role
execute "#{ envs } openstack role create user" do
  not_if "#{ envs } openstack role list | grep user"
end

# add user role to demo user
execute "#{ envs } openstack role add --project demo --user demo user" do
  not_if "#{ envs } openstack role list --project demo --user demo | awk '{ print $4 }' | grep user"
end

# disable temporary authentication token mechanism
file "/etc/keystone/keystone-paste.ini" do
  action :edit
  block do |content|
    content.gsub!(/ admin_token_auth /," ")
  end
end


