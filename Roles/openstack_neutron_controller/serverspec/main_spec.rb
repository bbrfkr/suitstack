require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_neutron_controller']['mariadb_pass']
scripts_dir = property['openstack_neutron_controller']['scripts_dir']
keyfiles_dir = property['openstack_neutron_controller']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_neutron_controller") do
  describe ("check neutron database is created") do
    describe command("mysql -u root -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /neutron/ }
    end
  end

  describe ("check permissions is granted to neutron database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'neutron'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`neutron\\`.* TO 'neutron'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'neutron'@'%'\" | grep \"ALL PRIVILEGES ON \\`neutron\\`.* TO 'neutron'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check neutron user is created") do
    describe command("#{ script } openstack user list") do
      its(:stdout) { should match /neutron/ }
    end
  end

  describe ("check grant admin role to neutron user") do
    describe command("#{ script } openstack role list --project service --user neutron | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check neutron service entity is created") do
    describe command("#{ script } openstack service list") do
      its(:stdout) { should match /neutron/ }
    end
  end

  describe ("check endpoints for neutron are created") do
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep neutron") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check packages are installed") do
    packages = ["openstack-neutron", "openstack-neutron-ml2", \
                "openstack-neutron-linuxbridge", "ebtables"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check plugin.ini symbolic link is created") do
    describe file("/etc/neutron/plugin.ini") do
      it { should be_symlink }
      it { should be_linked_to "/etc/neutron/plugins/ml2/ml2_conf.ini" }
    end
  end

  describe ("check neutron database is deployed") do
    describe file("#{ keyfiles_dir }/openstack_neutron_controller/neutron_db_manage") do
      it { should exist }
    end
  end

  describe ("check openstack-nova-api service is running") do
    describe service("openstack-nova-api") do
      it { should be_running }
    end
  end

  describe ("check services are enabled and running") do
    services = ["neutron-server", "neutron-linuxbridge-agent", \
                "neutron-dhcp-agent", "neutron-metadata-agent", \
                "neutron-l3-agent"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end

