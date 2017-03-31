require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

hostname = run_command("uname -n").stdout.chomp
controller = node['openstack_ntp']['controller']

# install chrony
package "chrony" do
  action :install
end

# add entry ntp server
file "/etc/chrony.conf" do
  action :edit
  notifies :restart, "service[chronyd]"
  block do |content|
    marker = "# Please consider joining the pool (http://www.pool.ntp.org/join.html).\n"
    entry_ntp_servers = "server #{ controller } iburst\n"
    if hostname == controller 
      entry_ntp_servers = ""
      node['openstack_ntp']['ntp_servers'].each do |ntp_server|
        entry_ntp_servers += "server " + ntp_server[:server] + " iburst\n"
      end
    end

    if not (content =~ /^#{ entry_ntp_servers }/)
      content.gsub!(/^server.*\n/, "")
      content.gsub!(marker, marker + entry_ntp_servers)
    end
  end
end  

# add entry of network to allow to sync time when target is controller node

if hostname == controller
  file "/etc/chrony.conf" do
    action :edit
    notifies :restart, "service[chronyd]"
    block do |content|
      marker = "# Allow NTP client access from local network.\n"

      entry_allow_networks = ""
      node['openstack_ntp']['allow_sync'].each do |network|
        entry_allow_networks += "allow " + network['network'] + "\n"
      end

      if not (content =~ /^#{ entry_allow_networks }/)
        content.gsub!(/^allow.*\n/, "")
        content.gsub!(marker, marker + entry_allow_networks)
      end
    end
  end
end

# enable chronyd
service "chronyd" do
  action [:enable, :start]
end
