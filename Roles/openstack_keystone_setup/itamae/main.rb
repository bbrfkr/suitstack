require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

admin_token = node['openstack_keystone_setup']['admin_token']
controller = node['openstack_keystone_setup']['controller']
region = node['openstack_keystone_setup']['region']
domain = node['openstack_keystone_setup']['domain']
admin_pass = node['openstack_keystone_setup']['admin_pass']
demo_pass = node['openstack_keystone_setup']['demo_pass']
scripts_dir = node['openstack_keystone_setup']['scripts_dir']

envs = "OS_TOKEN=#{ admin_token } OS_URL=http://#{ controller }:35357/v3 OS_IDENTITY_API_VERSION=3"

# create service entity
execute "#{ envs } openstack service create --name keystone --description \"OpenStack Identity\" identity" do
  not_if "#{ envs } openstack service list | grep keystone"
end

# create endpoints
execute "#{ envs } openstack endpoint create --region #{ region } identity public http://#{ controller }:5000/v3" do
  not_if "#{ envs } openstack endpoint list | awk '{ print $6, $12 }' | grep keystone | grep public"
end

execute "#{ envs } openstack endpoint create --region #{ region } identity internal http://#{ controller }:5000/v3" do
  not_if "#{ envs } openstack endpoint list | awk '{ print $6, $12 }' | grep keystone | grep internal"
end

execute "#{ envs } openstack endpoint create --region #{ region } identity admin http://#{ controller }:35357/v3" do
  not_if "#{ envs } openstack endpoint list | awk '{ print $6, $12 }' | grep keystone | grep admin"
end

# create domain
execute "#{ envs } openstack domain create --description \"Default Domain\" #{ domain }" do
  not_if "#{ envs } openstack domain list | grep #{ domain }"
end

# create admin project
execute "#{ envs } openstack project create --domain #{ domain } --description \"Admin Project\" admin" do
  not_if "#{ envs } openstack project list | grep admin"
end

# create admin user
execute "#{ envs } openstack user create --domain #{ domain } --password #{ admin_pass } admin" do
  not_if "#{ envs } openstack user list | grep admin"
end

# create admin role
execute "#{ envs } openstack role create admin" do
  not_if "#{ envs } openstack role list | grep admin"
end

# add admin role to admin user
execute "#{ envs } openstack role add --project admin --user admin admin" do
  not_if "#{ envs } openstack role list --project admin --user admin | awk '{ print $4 }' | grep admin"
end

# create service project
execute "#{ envs } openstack project create --domain #{ domain } --description \"Service Project\" service" do
  not_if "#{ envs } openstack project list | grep service"
end

# create demo project
execute "#{ envs } openstack project create --domain #{ domain } --description \"Demo Project\" demo" do
  not_if "#{ envs } openstack project list | grep demo"
end

# create demo user
execute "#{ envs } openstack user create --domain #{ domain } --password #{ demo_pass } demo" do
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

# create directory for openrc files
directory scripts_dir do
  action :create
end

# create openrc files
template "#{ scripts_dir }/admin-openrc" do
  action :create
  variables(domain: domain, \
            admin_pass: admin_pass, \
            controller: controller )
end

template "#{ scripts_dir }/demo-openrc" do
  action :create
  variables(domain: domain, \
            demo_pass: demo_pass, \
            controller: controller )
end

