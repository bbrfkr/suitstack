require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

describe ("openstack_network") do
  describe ("check NetworkManager and firewalld are disabled and stopped") do
    services = ["NetworkManager", "firewalld"]
    services.each do |srv|
      describe service(srv) do
        it { should_not be_enabled }
        it { should_not be_running }
      end
    end
  end

  describe ("check SELinux is disabled") do
    describe command("getenforce") do
      its(:stdout) { should eq "Disabled\n" }
    end
  end

  describe ("check hostname is set") do
    describe command("uname -n") do
      its(:stdout) { should eq property['openstack_network']['hostname'] + "\n" }
    end
  end

  describe ("check hosts entries are available") do
    property['openstack_network']['hosts_entries'].each do |hosts_entry|
      hosts_entry['server'].split(/\s+/).each do |server|
        describe host(server) do
          it { should be_reachable }
          if hosts_entry['ip'] =~ /^.*\..*\..*\..*$/
            its(:ipv4_address) { should eq hosts_entry['ip'] }
          else
            its(:ipv6_address) { should eq hosts_entry['ip'] }
          end
        end
      end 
    end
  end

  describe ("check dns servers are set") do
    property['openstack_network']['dns_servers'].each do |dns_server|
      describe file("/etc/resolv.conf") do
        its(:content) { should match /^nameserver\s+#{ dns_server['server'] }$/ }
      end
    end
  end

  describe ("check be able to access internet") do
    describe host("www.yahoo.co.jp") do
      it { should be_reachable }
    end
  end
end
