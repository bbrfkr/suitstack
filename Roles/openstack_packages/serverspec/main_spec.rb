require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_packages") do
  describe ("check repository is registered") do
    describe package("centos-release-openstack-mitaka") do
      it { should be_installed }
    end
  end

  describe ("check openstack packages is installed") do
    packages = ["python-openstackclient", "openstack-selinux"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end
end

