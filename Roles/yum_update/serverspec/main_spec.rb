require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("yum_update") do
  describe ("check all packages are updated") do
    describe command("LANG=C sudo yum update --assumeno | grep \"No packages marked for update\"") do
      its(:exit_status) { should eq 0 }
    end
  end
end

