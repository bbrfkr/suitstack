require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

status = property['selinux']['status']

describe ("selinux") do
  describe ("check selinux status is appropriate") do
    describe command("getenforce | grep \"#{ status }\"") do
      its(:exit_status) { should eq 0 }
    end
  end
end

