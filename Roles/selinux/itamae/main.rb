require './Modules/defaults'
require './Modules/reboot'
node.reverse_merge!(defaults_load(__FILE__))

status = node['selinux']['status']
reboot_waittime = node['selinux']['reboot_waittime']

if status != "Enforcing" && status != "Permissive" && status != "Disabled"
  fail 'parameter "status" should be "Enforcing" or "Permissive" or "Disabled"'
end

change_flag = run_command("getenforce | grep #{ status }", error: false).exit_status

if change_flag != 0
  file "/etc/selinux/config" do
    action :edit
    block do |content|
      content.gsub!(/^SELINUX=.*$/, "SELINUX=#{ status.downcase }")
    end
  end

  if status == "Enforcing"
    execute "restorecon -R /"
  end

  reboot(reboot_waittime)
end

