require './Modules/defaults'
require './Modules/blockinfile'
node.reverse_merge!(defaults_load(__FILE__))

controller = node['openstack_horizon']['controller']
domain = node['openstack_horizon']['domain']
timezone = node['openstack_horizon']['timezone']

# install package
package "openstack-dashboard" do
  action :install
end

# edit config file
file "/etc/openstack-dashboard/local_settings" do
  action :edit
  notifies :restart, "service[httpd]", :immediately
  notifies :restart, "service[memcached]", :immediately
  block do |content|
    content.gsub!(/^OPENSTACK_HOST = .*$/, "OPENSTACK_HOST = \"#{ controller }\"") 
    content.gsub!(/^ALLOWED_HOSTS = .*$/, "ALLOWED_HOSTS = ['*', ]") 
    memcached_config = <<-"EOF"
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': '#{ controller }:11211',
    }
}
    EOF
    content.gsub!(/^(SESSION_ENGINE = .*?)*CACHES = \{\n.*?\n\}$/m, memcached_config.chomp)
    content.gsub!(/^OPENSTACK_KEYSTONE_URL = .*$/, "OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST")
    content.gsub!(/^.?OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = .*$/, "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True")
    api_ver_config = <<-"EOF"
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
    EOF
    content.gsub!(/^.?OPENSTACK_API_VERSIONS = \{\n.*?\n.?\}/m, api_ver_config.chomp)
    content.gsub!(/^.?OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = .*/, "OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"#{ domain }\"")
    content.gsub!(/^OPENSTACK_KEYSTONE_DEFAULT_ROLE = .*/, "OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"")
    content.gsub!(/^TIME_ZONE = .*$/, "TIME_ZONE = \"#{ timezone }\"")
  end
end

# for restart services
service "httpd"
service "memcached"

