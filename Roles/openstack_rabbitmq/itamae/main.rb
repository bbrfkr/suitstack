require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

# install packages
package "rabbitmq-server" do
  action :install
end

# enable and start service
service "rabbitmq-server" do
  action [:enable, :start]
end

# add openstack user
execute "rabbitmqctl add_user openstack #{ node['openstack_rabbitmq']['rabbitmq_pass'] }" do
  not_if "rabbitmqctl list_users | grep openstack"
end

# set permission for openstack user
execute "rabbitmqctl set_permissions openstack \".*\" \".*\" \".*\"" do
  not_if "rabbitmqctl list_permissions | grep openstack | grep \"\\.\\*\\s*\\.\\*\\s*\\.\\*\""
end
