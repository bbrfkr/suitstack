def reboot(reboot_waittime)
  # reboot server when hostname or selinux state is changed
  local_ruby_block "reboot server" do
    block do
      begin
        opt = { :port => ENV['CONN_PORT'] }
        if ENV['CONN_IDKEY'] != nil
          opt[:keys] = ["Env/" + ENV['CONN_IDKEY']]
        end
        if ENV['CONN_PASSPHRASE'] != nil
          opt[:passphrase] = ENV['CONN_PASSPHRASE']
        end
        if ENV['CONN_PASS'] != nil
          opt[:password] = ENV['CONN_PASS']
        end
        Net::SSH.start(ENV['CONN_HOST'], ENV['CONN_USER'], opt) do |ssh|
          if ENV['CONN_USER'] == "root"
            ssh.exec "reboot"
          else
            channel = ssh.open_channel do |ch|
              channel.request_pty do |ch, success|
                raise "could not obtain pty" if !success
              end
              channel.exec "sudo reboot"
            end
            ssh.loop
          end
        end
      rescue IOError
        puts "\e[31m***************************************************\e[0m"
        puts "\e[31mrebooting server is required!! \e[0m"
        puts "\e[31mserver is rebooted. please wait for #{ reboot_waittime } minutes... \e[0m"
        puts "\e[31m***************************************************\e[0m"
        sleep(reboot_waittime * 60)
      end
    end
  end
end
