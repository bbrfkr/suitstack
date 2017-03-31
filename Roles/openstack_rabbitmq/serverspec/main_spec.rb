require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_rabbitmq") do
  describe ("check package is installed") do
    describe package("rabbitmq-server") do
      it { should be_installed }
    end
  end

  describe ("check service is enabled and started") do
    describe service("rabbitmq-server") do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe ("check openstack user exists") do
    describe command("rabbitmqctl list_users | grep openstack") do
      its(:exit_status) { should eq 0 }
    end
  end

  describe ("check permission is set for openstack user") do
    describe command("rabbitmqctl list_permissions | grep openstack | grep \"\\.\\*\\s*\\.\\*\\s*\\.\\*\"") do
      its(:exit_status) { should eq 0 }
    end
  end
end

