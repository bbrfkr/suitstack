require 'infrataster/rspec'
require 'serverspec'

# dummy setting for avoid warning
set :backend, :ssh
set :request_pty, true

connection = ENV['CONN_NAME']
if File.exists?('Env/properties.yml')
  if not File.zero?('Env/properties.yml')
    properties = YAML.load_file('Env/properties.yml')
    if properties[connection] != nil
      set_property properties[connection]
    else
      set_property ({})
    end
  end
end

Infrataster::Server.define(ENV['CONN_NAME'].to_sym) do |server|
  server.address = ENV['CONN_HOST']
  opt = { user: ENV['CONN_USER'], port: ENV['CONN_PORT'].to_i }
  if ENV['CONN_IDKEY'] != nil
    opt[:keys] = ["Env/" + ENV['CONN_IDKEY']]
  end
  if ENV['CONN_PASSPHRASE'] != nil
    opt[:passphrase] = ENV['CONN_PASSPHRASE']
  end
  if ENV['CONN_PASS'] != nil
    opt[:password] = ENV['CONN_PASS']
  end
  server.ssh = opt
end

