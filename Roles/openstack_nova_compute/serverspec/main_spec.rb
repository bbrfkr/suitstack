require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_nova_compute") do
  describe ("check package is installed") do
    describe package("openstack-nova-compute") do
      it { should be_installed }
    end
  end

  hw_support = Specinfra.backend.run_command("egrep -c '(vmx|svm)' /proc/cpuinfo").stdout.chomp

  if hw_support == "0"
    describe ("check config is set when hardware support for virtualization is not supported ") do
      describe file("/etc/nova/nova.conf") do
        its(:content) { should match /^virt_type = qemu$/ }
      end
    end
  else
    describe ("check config is set when hardware support for virtualization is supported ") do
      describe file("/etc/nova/nova.conf") do
        its(:content) { should_not match /^virt_type = qemu$/ }
      end
    end
  end

  describe ("check services are enabled and started") do
    services = ["libvirtd", "openstack-nova-compute"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end
