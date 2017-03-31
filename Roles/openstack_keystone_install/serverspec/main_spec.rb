require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_keystone_install']['mariadb_pass']
keyfiles_dir = property['openstack_keystone_install']['keyfiles_dir']

describe ("openstack_keystone_install") do
  describe ("check database is created") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show databases;\"") do
      its(:stdout) { should match /keystone/}
    end
  end

  describe ("check grant of database is set") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'keystone'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`keystone\\`.* TO 'keystone'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'keystone'@'%'\" | grep \"ALL PRIVILEGES ON \\`keystone\\`.* TO 'keystone'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check packages are installed") do
    packages = ["openstack-keystone", "httpd", "mod_wsgi"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check keystone service database is deployed") do
    describe file("#{ keyfiles_dir }/openstack_keystone_install/db_sync") do
      it { should exist }
    end
  end

  describe ("check fernet key is initialized") do
    describe file("#{ keyfiles_dir }/openstack_keystone_install/fernet_setup") do
      it { should exist }
    end
  end

  describe ("check wsgi setting is set") do
    describe file("/etc/httpd/conf.d/wsgi-keystone.conf") do
      it { should exist }
    end
  end

  describe ("check service is enabled and started") do
    describe service("httpd") do
      it { should be_enabled }
      it { should be_running }
    end
  end
end

