require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

mariadb_pass = property['openstack_glance']['mariadb_pass']
scripts_dir = property['openstack_glance']['scripts_dir']
store_images_dir = property['openstack_glance']['store_images_dir']
keyfiles_dir = property['openstack_glance']['keyfiles_dir']

admin_script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_glance") do
  describe ("check glance database is created") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show databases\"") do
      its(:stdout) { should match /glance/ }
    end
  end

  describe ("check permissions are granted to glance database") do
    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'glance'@'localhost'\" | grep \"ALL PRIVILEGES ON \\`glance\\`.* TO 'glance'@'localhost'\"") do
      its(:exit_status) { should eq 0 }
    end

    describe command("mysql -uroot -p#{ mariadb_pass } -e \"show grants for 'glance'@'%'\" | grep \"ALL PRIVILEGES ON \\`glance\\`.* TO 'glance'@'%'\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check glance user is created") do
    describe command("#{ admin_script } openstack user list") do
      its(:stdout) { should match /glance/ }
    end
  end

  describe ("check admin role is granted to glance user") do
    describe command("#{ admin_script } openstack role list --project service --user glance | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check glance service entity is created") do
    describe command("#{ admin_script } openstack service list") do
      its(:stdout) { should match /glance/ }
    end
  end

  describe ("check endpoints for glance are created") do
    describe command("#{ admin_script } openstack endpoint list | awk '{ print $6, $12 }' | grep glance") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check packages are installed") do
    describe package("openstack-glance") do
      it { should be_installed }
    end
  end

  describe ("check directory to store images is set") do
    describe file("#{ store_images_dir }") do
      it { should be_directory }
      it { should be_mode 750 }
      it { should be_owned_by "glance" }
      it { should be_grouped_into "glance" }
    end

    describe file("/etc/glance/glance-api.conf") do
      its(:content) { should match /\[glance_store\].*filesystem_store_datadir = #{ store_images_dir }/m }
    end
  end

  describe ("check glance servcie database is deployed") do
    describe file("#{ keyfiles_dir }/openstack_glance/db_sync") do
      it { should exist }
    end
  end

  describe ("check services are enabled and started") do
    services = ["openstack-glance-api","openstack-glance-registry"]
    services.each do |srv|
      describe service (srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end

