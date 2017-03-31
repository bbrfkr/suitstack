require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

scripts_dir = property['openstack_keystone_setup']['scripts_dir']
domain = property['openstack_keystone_setup']['domain']

admin_script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_keystone_setup") do
  describe ("check service entity exists") do
    describe command("#{ admin_script } openstack service list") do
      its(:stdout) { should match /keystone/ }
    end
  end

  describe ("check endpoints are created") do
    describe command("#{ admin_script } openstack endpoint list | awk '{ print $6, $12 }' | grep keystone") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check domain are created") do
    describe command("#{ admin_script } openstack domain list") do
      its(:stdout) { should match /#{ domain }/ }
    end
  end

  describe ("check admin, demo and service projects are created") do
    describe command("#{ admin_script } openstack project list") do
      its(:stdout) { should match /admin/ }
      its(:stdout) { should match /service/ }
      its(:stdout) { should match /demo/ }
    end
  end

  describe ("check admin and demo users are created") do
    describe command("#{ admin_script } openstack user list") do
      its(:stdout) { should match /admin/ }
      its(:stdout) { should match /demo/ }
    end
  end

  describe ("check admin and user roles are created") do
    describe command("#{ admin_script } openstack role list") do
      its(:stdout) { should match /admin/ }
      its(:stdout) { should match /user/ }
    end
  end

  describe ("check grant admin role to admin user") do
    describe command("#{ admin_script } openstack role list --project admin --user admin | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check grant user role to demo user") do
    describe command("#{ admin_script } openstack role list --project demo --user demo | awk '{ print $4 }'") do
      its(:stdout) { should match /user/ }
    end
  end

  describe ("check temporary authentication token mechanisim is disabled") do
    describe file("/etc/keystone/keystone-paste.ini") do
      its(:content) { should_not match /\sadmin_token_auth\s/ }
    end
  end

  describe ("check openrc files is set") do
    describe file("#{ scripts_dir }/admin-openrc") do
      it { should exist }
    end
    describe file("#{ scripts_dir }/demo-openrc") do
      it { should exist }
    end
  end
end

