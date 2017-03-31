require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

tmp_dir = node['openstack_mariadb']['tmp_dir']
$mysql_secure_installtion = 0

# install packages
packages = ["mariadb", "mariadb-server", "python2-PyMySQL", "expect"]
packages.each do |pkg|
  package pkg do
    action :install
  end
end

# set config file
template "/etc/my.cnf.d/openstack.cnf" do
  action :create
  variables(bind_address: node['openstack_mariadb']['bind_address'])
  notifies :restart, "service[mariadb]"
end

# enable mariadb
service "mariadb" do
  action [:enable, :start]
end

# mysql secure installation
directory tmp_dir do
  action :create
  only_if "mysql -uroot -e \"show databases;\""
end

remote_file tmp_dir + "/mysql_secure_installation.sh" do
  action :create
  mode "0755"
  only_if "mysql -uroot -e \"show databases;\""
end

execute tmp_dir + "/mysql_secure_installation.sh " + node['openstack_mariadb']['mariadb_pass'] do
  action :run
  only_if "mysql -uroot -e \"show databases;\""
end

directory tmp_dir do
  action :delete
end

