require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_mongodb") do
  packages = ["mongodb-server", "mongodb"]
  describe ("check packages are installed") do
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check service is enable") do
    describe service("mongod") do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe ("check specified bind_ip is set") do
    describe file("/etc/mongod.conf") do
      its(:content) { should match /^bind_ip = #{ property['openstack_mongodb']['bind_ip'] }$/ }
    end
  end

  describe ("check smallfiles switch is as specified") do
    describe file("/etc/mongod.conf") do
      its(:content) { should match /^smallfiles = #{ property['openstack_mongodb']['smallfiles'].to_s }$/ }
    end
  end
end

