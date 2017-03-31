require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

cinder_devices = property['openstack_cinder_storage']['cinder_devices']
cinder_vg = property['openstack_cinder_storage']['cinder_vg']

describe ("openstack_cinder_storage") do
  describe ("check lvm2 package is installed") do
    describe package "lvm2" do
      it { should be_installed }
    end
  end

  describe ("check lvm2-lvmetad service is enabled and started") do
    describe service("lvm2-lvmetad") do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe ("check physical volumes are created") do
    cinder_devices.each do |dev|
      describe command("pvs | grep \"/dev/#{dev}\"") do
        its(:exit_status) { should eq 0 }
      end
    end
  end

  describe ("check volume group is created") do
    describe command ("vgs | grep \"#{ cinder_vg }\"") do
      its(:exit_status) { should eq 0 }
    end
  end

  root_dev = Specinfra.backend.run_command("df | grep /$ | awk '{ print $1 }'").stdout.chomp
  is_lvm = root_dev =~ /\/mapper\// ? true : false

  if is_lvm
    describe ("check devices with root partition are filtered in lvm.conf") do
      root_dev.slice!("/dev/mapper/")
      vg = (root_dev[/.*-/])[0..-2]
      root_devs = Specinfra.backend.run_command("pvs | grep #{ vg } | awk '{ print $1 }' | awk -F/ '{ print $3 }' | awk '{ sub(/[0-9]$/, \"\", $0) ; print $0 }'").stdout.chomp
      root_devs = root_devs.split("\n").uniq
      
      root_devs_str = ""
      root_devs.each do |dev|
        root_devs_str += "\"a/#{dev}/\", "
      end

      describe file("/etc/lvm/lvm.conf") do
        its(:content) { should match /^\s*filter = \[.*#{ root_devs_str }.*\]\s*$/}
      end
    end
  end

  describe ("check cinder devices are filtered in lvm.conf") do
    filter_devs = []

    cinder_devices.each do |dev|
      if dev =~ /[0-9]$/
        dev = dev[0,-2]
      end
      filter_devs.push(dev)
    end

    filter_devs_str = ""
    filter_devs.each do |dev|
      filter_devs_str += "\"a/#{dev}/\", "
    end

    describe file("/etc/lvm/lvm.conf") do
      its(:content) { should match /^\s*filter = \[.*#{ filter_devs_str }.*\]\s*$/ }
    end
  end

  describe ("check cinder packages are installed") do
    packages = ["openstack-cinder", "targetcli", "python-keystone"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check cinder services are enabled and started") do
    services = ["openstack-cinder-volume", "target"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end
