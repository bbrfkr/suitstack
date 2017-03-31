require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_mariadb") do
  packages = ["mariadb", "mariadb-server", "python2-PyMySQL"]
  describe ("check packages are installed") do
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check service is enable") do
    describe service("mariadb") do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe ("check specified bind-address is set") do
    describe file("/etc/my.cnf.d/openstack.cnf") do
      its(:content) { should match /^bind-address = #{ property['openstack_mariadb']['bind_address'] }$/ }
    end
  end
end

