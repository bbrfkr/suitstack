require './Modules/defaults'
node.reverse_merge!(defaults_load(__FILE__))

directory "#{ node['suit_keyfiles']['keyfiles_dir'] }" do
  action :create
end

