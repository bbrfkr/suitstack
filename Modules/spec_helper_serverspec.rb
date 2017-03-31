require 'serverspec'
require 'net/ssh'
require 'yaml'

set :backend, :ssh
set :request_pty, true

connection = ENV['CONN_NAME']
host = ENV['CONN_HOST']
if File.exists?('Env/properties.yml')
  if not File.zero?('Env/properties.yml')
    properties = YAML.load_file('Env/properties.yml')
    if properties[connection] != nil
      set_property(properties[connection])
    else
      set_property({})
    end
  end
end

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

options = Net::SSH::Config.for(host)

options[:user] = ENV['CONN_USER']
if ENV['CONN_PASS'] != nil
  options[:password] = ENV['CONN_PASS']
end
if ENV['CONN_IDKEY'] != nil
  options[:keys] = "Env/" + ENV['CONN_IDKEY']
end
if ENV['CONN_PASSPHRASE'] != nil
  options[:passphrase] = ENV['CONN_PASSPHRASE']
end
options[:port] = ENV['CONN_PORT']

set :host,        options[:host_name] || host
set :ssh_options, options

# Disable sudo
# set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C' 

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
