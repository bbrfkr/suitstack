require './Modules/spec_helper_serverspec'
require './Modules/defaults'
property.reverse_merge!(defaults_load(__FILE__))

scripts_dir = property['openstack_swift_proxy']['scripts_dir']
storage_nodes = property['openstack_swift_proxy']['storage_nodes']

script = "source #{ scripts_dir }/admin-openrc &&"

describe ("openstack_swift_proxy") do
  describe ("check swift user is created") do
    describe command("#{ script } openstack user list") do
      its(:stdout) { should match /swift/ }
    end
  end

  describe ("check grant admin role to swift user") do
    describe command("#{ script } openstack role list --project service --user swift | awk '{ print $4 }'") do
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check swift service entity is created") do
    describe command("#{ script } openstack service list") do
      its(:stdout) { should match /swift/ }
    end
  end

  describe ("check endpoints for swift are created") do
    describe command("#{ script } openstack endpoint list | awk '{ print $6, $12 }' | grep swift") do
      its(:stdout) { should match /public/ }
      its(:stdout) { should match /internal/ }
      its(:stdout) { should match /admin/ }
    end
  end

  describe ("check swift packages are installed") do
    packages = ["openstack-swift-proxy", "python2-swiftclient", \
                "python-keystoneclient", "python-keystonemiddleware", \
                "memcached"]
    packages.each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end
  end

  describe ("check account ring has information of all storage nodes") do
    storage_nodes.each do |str_node|
      str_node['devices'].each do |dev|
        describe command("cd /etc/swift && swift-ring-builder account.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\"") do
          its(:exit_status) { should eq 0 }
        end
      end
    end
  end

  describe ("check container ring has information of all storage nodes") do
    storage_nodes.each do |str_node|
      str_node['devices'].each do |dev|
        describe command("cd /etc/swift && swift-ring-builder container.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\"") do
          its(:exit_status) { should eq 0 }
        end
      end
    end
  end

  describe ("check object ring has information of all storage nodes") do
    storage_nodes.each do |str_node|
      str_node['devices'].each do |dev|
        describe command("cd /etc/swift && swift-ring-builder object.builder | grep \"#{ str_node['mgmt_ip'] }\"| grep \"#{ dev }\"") do
          its(:exit_status) { should eq 0 }
        end
      end
    end
  end

  describe ("check ownership of the config directory") do
    describe command("(ls -ld /etc/swift && ls -lR /etc/swift) | grep -e \"[d|-]\\([r|-][w|-][x|-]\\)\\{3\\}\" | grep -v \"root swift\"") do
      its(:exit_status) { should_not eq 0 }
    end
  end

  describe ("check proxy services are enabled and running") do
    services = ["openstack-swift-proxy", "memcached"]
    services.each do |srv|
      describe service(srv) do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end
