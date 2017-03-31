require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

hostname = Specinfra.backend.run_command("uname -n").stdout.chomp
controller = property['openstack_ntp']['controller']

describe ("openstack_ntp") do
  describe ("check chrony is installed") do
    describe package("chrony") do
      it { should be_installed }
    end
  end

  describe ("check chronyd is enabled") do
    describe service("chronyd") do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe ("check ntp servers are specified") do
    describe file("/etc/chrony.conf") do
      if hostname == controller
        property['openstack_ntp']['ntp_servers'].each do |ntp_server|
          its(:content) { should match /^server #{ ntp_server['server'] } iburst$/}
        end
      else
        its(:content) { should match /^server #{ controller } iburst$/}
      end
    end
  end

  if hostname == controller
    describe ("check specified network is allowed to sync time") do
      describe file("/etc/chrony.conf") do
        property['openstack_ntp']['allow_sync'].each do |network|
          its(:content) { should match /^allow #{ network['network'] }$/}
        end
      end
    end
  end

  describe ("check time is syncronized actually") do
    describe command("chronyc sources") do
      its(:stdout) { should match /^\^\*.*$/ }
    end
  end
end
