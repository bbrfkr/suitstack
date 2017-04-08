require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

controller = property['openstack_memcached']['controller']

describe ("openstack_memcached") do
  describe ("check packages are installed") do
    packages = ["memcached", "python-memcached"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check listen address includes controller") do
    describe file("/etc/sysconfig/memcached") do
      its(:content) { should match /#{ controller }/ }
    end
  end

  describe ("check service is enabled and started") do
    describe service("memcached") do
      it { should be_enabled }
      it { should be_running }
    end
  end
end

