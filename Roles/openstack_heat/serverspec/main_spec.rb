require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_heat']['mariadb_pass']
scripts_dir = property['openstack_heat']['scripts_dir']
keyfiles_dir = property['openstack_heat']['keyfiles_dir']

script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_heat") do
  describe ("check heat database is created") do
    describe command("mysql -u root -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /heat/ }
    end
  end

  describe ("check permissions is granted to heat database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'heat'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`heat\\`.* TO 'heat'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'heat'@'%'\" | grep \"ALL PRIVILEGES ON \\`heat\\`.* TO 'heat'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check heat user is created") do
    describe command("#{ script } openstack user list | grep -v \"heat_domain_admin\"") do
      its(:stdout) { should match /heat/ }
    end
  end

  describe ("check admin role is granted to haet user") do
    describe command("#{ script } openstack role list --project service --user heat | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check heat and heat-cfn service entities are created") do
    describe command("#{ script } openstack service list | grep -v \"heat-cfn\"") do
      its(:stdout) { should match /heat/ }
    end
    describe command("#{ script } openstack service list") do
      its(:stdout) { should match /heat-cfn/ }
    end
  end

  describe ("check endpoints for heat, heat-cfn are created") do
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep heat | grep -v heat-cfn") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep heat-cfn") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check heat domain is created") do
    describe command("#{ script } openstack domain list | awk '{ print $4 }'") do
      its(:stdout) { should match /heat/ }
    end
  end

  describe ("check heat_domain_admin user is created") do
    describe command("#{ script } openstack user list --domain heat") do
      its(:stdout) { should match /heat_domain_admin/ }
    end
  end

  describe ("check admin role is granted to heat_domain_admin user") do
    describe command("#{ script } openstack role list --domain heat --user-domain heat --user heat_domain_admin | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end 
  end

  describe ("check heat_stack_owner and heat_stack_user roles are created") do
    describe command("#{ script } openstack role list") do
      its(:stdout) { should match /heat_stack_owner/ }
      its(:stdout) { should match /heat_stack_user/ }
    end
  end

  describe ("check package is installed") do
    packages = ["openstack-heat-api", "openstack-heat-api-cfn", "openstack-heat-engine"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check heat database is deployed") do
    describe file("#{ keyfiles_dir }/openstack_heat/db_sync") do
      it { should exist }
    end
  end

  describe ("check services are enabled and running") do
    services = ["openstack-heat-api", "openstack-heat-api-cfn", "openstack-heat-engine"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end

