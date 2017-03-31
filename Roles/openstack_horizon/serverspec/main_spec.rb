require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_horizon") do
  describe ("check package is installed") do
    describe package("openstack-dashboard") do
      it { should be_installed }
    end
  end

  describe ("check services is running") do
    services = ["httpd", "memcached"]
    services.each do |srv|
      describe service(srv) do
        it { should be_running }
      end
    end
  end
end
