require './Modules/defaults'
require './Modules/reboot'
node.reverse_merge!(defaults_load(__FILE__))

reboot_waittime = node['yum_update']['reboot_waittime']

update_flag = run_command("LANG=C sudo yum update --assumeno | grep \"No packages marked for update\"", error: false).exit_status

if update_flag != 0
  # execute yum update
  execute "yum update -y"

  # reboot server 
  reboot(reboot_waittime)
end

