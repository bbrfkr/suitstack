require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_neutron_compute") do
  describe ("check packages are installed") do
    packages = ["openstack-neutron-linuxbridge", "ebtables", "ipset"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check openstack-nova-compute service is running") do
    describe service("openstack-nova-compute") do
      it { should be_running }
    end
  end

  describe ("check service is enabled and running") do
    describe service("neutron-linuxbridge-agent") do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
