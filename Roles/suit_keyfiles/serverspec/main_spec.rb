require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("suit_keyfiles") do
  describe ("check dir for key-files is created") do
    describe file(property['suit_keyfiles']['keyfiles_dir']) do
      it { should be_directory }
    end
  end
end

