require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_cinder_controller']['mariadb_pass']
scripts_dir = property['openstack_cinder_controller']['scripts_dir']
keyfiles_dir = property['openstack_cinder_controller']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_cinder_controller") do
  describe ("check cinder database is created") do
    describe command("mysql -u root -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /cinder/ }
    end
  end

  describe ("check permissions is granted to cinder database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'cinder'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`cinder\\`.* TO 'cinder'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'cinder'@'%'\" | grep \"ALL PRIVILEGES ON \\`cinder\\`.* TO 'cinder'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check cinder user is created") do
    describe command("#{ script } openstack user list") do
      its(:stdout) { should match /cinder/ }
    end
  end

  describe ("check grant admin role to cinder user") do
    describe command("#{ script } openstack role list --project service --user cinder | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check cinder service entities are created") do
    describe command("#{ script } openstack service list | grep -v \"cinderv2\"") do
      its(:stdout) { should match /cinder/ }
    end
    describe command("#{ script } openstack service list") do
      its(:stdout) { should match /cinderv2/ }
    end
  end

  describe ("check endpoints for cinder are created") do
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinder | grep -v cinderv2") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep cinderv2") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check package is installed") do
    describe package("openstack-cinder") do
      it { should be_installed }
    end
  end

  describe ("check cinder database is deployed") do
    describe file("#{ keyfiles_dir }/openstack_cinder_controller/db_sync") do
      it { should exist }
    end
  end

  describe ("check openstack-nova-api service is running") do
    describe service("openstack-nova-api") do
      it { should be_running }
    end
  end

  describe ("check services are enabled and running") do
    services = ["openstack-cinder-api", "openstack-cinder-scheduler"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end

