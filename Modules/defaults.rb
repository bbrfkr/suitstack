require 'yaml'
require 'active_support'
require 'active_support/core_ext'

def defaults_load(source_file)
  defaults_file = File.expand_path(File.dirname(source_file)) \
                  + "/../defaults/main.yml"
  if File.exists?(defaults_file)
    return(YAML.load_file(defaults_file))
  else
    return({})
  end
end
