require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

scripts_dir = property['openstack_keystone_setup']['scripts_dir']

admin_script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_keystone_setup") do
  describe ("check service projects are created") do
    describe command("#{ admin_script } openstack project list") do
      its(:stdout) { should match /service/ }
    end
  end

  describe ("check user roles are created") do
    describe command("#{ admin_script } openstack role list") do
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
  end
end

