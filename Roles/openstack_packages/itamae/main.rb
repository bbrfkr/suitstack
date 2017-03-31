require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

# register openstack repository
package "centos-release-openstack-mitaka" do
  action :install
end

# install openstack packages
packages = [ "python-openstackclient", "openstack-selinux"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

