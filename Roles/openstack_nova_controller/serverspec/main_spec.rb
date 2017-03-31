require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_nova_controller']['mariadb_pass']
scripts_dir = property['openstack_nova_controller']['scripts_dir']
keyfiles_dir = property['openstack_nova_controller']['keyfiles_dir']
cpu_allocation_ratio = property['openstack_nova_controller']['cpu_allocation_ratio']
ram_allocation_ratio = property['openstack_nova_controller']['ram_allocation_ratio']

script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_nova_controller") do
  describe ("check databases are created") do
    describe command("mysql -u root -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /nova_api/ }
    end

    describe command("mysql -u root -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /nova/ }
    end
  end

  describe ("check permissions are granted nova_api database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'nova'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`nova_api\\`.* TO 'nova'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end

    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'nova'@'%'\" | grep \"ALL PRIVILEGES ON \\`nova_api\\`.* TO 'nova'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check permissions are granted nova database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'nova'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end

    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'nova'@'%'\" | grep \"ALL PRIVILEGES ON \\`nova\\`.* TO 'nova'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check nova user is created") do
    describe command("#{ script } openstack user list") do
      its(:stdout) { should match /nova/ }
    end
  end

  describe ("check admin role is granted to nova user") do
    describe command("#{ script } openstack role list --project service --user nova | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check nova service entity is created") do
    describe command ("#{ script } openstack service list") do
      its(:stdout) { should match /nova/ }
    end
  end

  describe ("check endpoints for nova are created") do
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep nova") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check packages are installed") do
    packages = ["openstack-nova-api", "openstack-nova-conductor", \
                "openstack-nova-console", "openstack-nova-novncproxy", \
                "openstack-nova-scheduler"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check nova_api and nova databases are deployed") do
    describe file("#{ keyfiles_dir }/openstack_nova_controller/api_db_sync") do
      it { should exist }
    end

    describe file("#{ keyfiles_dir }/openstack_nova_controller/db_sync") do
      it { should exist }
    end
  end

  describe ("check nova services are enabled and started") do
    services = ["openstack-nova-api", "openstack-nova-consoleauth", \
                "openstack-nova-scheduler", "openstack-nova-conductor", \
                "openstack-nova-novncproxy.service"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end

  describe ("check cpu allocation ratio is specified") do
    describe file("/etc/nova/nova.conf") do
      its(:content) { should match /^cpu_allocation_ratio = #{ cpu_allocation_ratio }$/ }
    end
  end

  describe ("check ram allocation ratio is specified") do
    describe file("/etc/nova/nova.conf") do
      its(:content) { should match /^ram_allocation_ratio = #{ ram_allocation_ratio }$/ }
    end
  end
end

