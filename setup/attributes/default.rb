#
# Cookbook Name:: setup
# Attributes:: default
#








default[:setup][:name] = node[:opsworks][:stack][:name]

default[:setup][:apps] = [node[:opsworks][:stack][:name]]

default[:setup][:rebuild_indexes] = true

default[:setup][:env] = 'dev'

default[:setup][:home_dir] = '/vol/www'

default[:setup][:home] = '/vol/www/code'

default[:setup][:conf_home] = '/vol/conf'

default[:setup][:lib_home] = '/vol/lib'

default[:setup][:log_home] = '/vol/log'

default[:setup][:branch_name] = 'master'

default[:setup][:env_file_name] = "env.json"

default[:setup][:env_file] = node[:setup][:conf_home]+"/"+node[:setup][:env_file_name]

default[:setup][:s3env] = "dev"
default[:setup][:user] = "vagrant"
default[:setup][:group] = "developers"


default[:setup][:code_lang] ="nodejs"

default[:setup][:ports][:web_server] = 80

default[:setup][:ports][:api_server] = 8000

default[:setup][:ports][:admin_server] = 8888


default[:setup][:module_recipes] = [

]

default[:setup][:domain] = node[:opsworks][:instance][:ip]

default[:setup][:has_facebook] = true

default[:setup][:definitions] = {
    "env"=>node[:setup][:env],
}