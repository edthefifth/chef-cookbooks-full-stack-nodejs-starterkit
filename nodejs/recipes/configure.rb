# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

include_recipe "nodejs::service"
include_recipe "nodejs::update"
include_recipe "nodejs::update_codebases"

password = node[:deploy][:main_db][:environment_variables][:password_value]
api_protocol = node[:deploy].attribute?(:api) && node[:deploy][:api][:environment_variables].attribute?(:ssl) && node[:deploy][:api][:environment_variables][:protocol] == '1' ? "https" : "http"

api_host = node[:deploy].attribute?(:api) ? node[:deploy][:api][:domains].first : "localhost"
api_port = node[:deploy].attribute?(:api) ? node[:deploy][:api][:environment_variables][:port] : "443"


node[:deploy].each do |application, deploy|
  if not deploy[:environment_variables].has_key?('nodejs')
    Chef::Log.info("Skipping nodejs::update for #{application}")
    next
  end  
    unixid , user =  node["ssh_users"].first
    name = application.downcase
    dir = deploy[:environment_variables][:dir]
    doc_root = "#{dir}/#{deploy[:document_root]}"
    
    definitions = Hash.new
    
    definitions[:port] = deploy[:environment_variables][:proxy_port]
    definitions[:host] = "127.0.0.1"
    definitions[:ext_host] = deploy[:domains].first;
    definitions[:env_file] = node[:setup][:env_file]
    
    mongo_connection = "mongodb://"
    connection_iter=0;
    
    if node[:nodejs][:env] == 'dev'
      username = user[:name]
    else
      username = node['nginx']['user']
    end
    
    node[:opsworks][:layers]["main-db"][:instances].each do |db_server_name,db_server|
      if connection_iter == 0
        mongo_connection+="#{db_server[:private_ip]}:#{node[:main][:port]}"
      else
        mongo_connection+=",#{db_server[:private_ip]}:#{node[:main][:port]}"
      end
      connection_iter+=1
    end

    node[:opsworks][:layers]["backup-db"][:instances].each do |db_server_name,db_server|
      if connection_iter == 0
        mongo_connection+="#{db_server[:private_ip]}:#{node[:backup][:port]}"
      else
        mongo_connection+=",#{db_server[:private_ip]}:#{node[:backup][:port]}"
      end
      connection_iter+=1
    end
    
    mongo_connection+="/core?replicaSet=#{node[:mongodb][:replicaset_name]}"
    
  
    api_connection="#{api_protocol}://#{api_host}:#{api_port}"
  
  
    definitions[:mongodb] = mongo_connection
    definitions[:api] = api_connection
    definitions[:paginate] = Hash.new
    definitions[:paginate][:default] = node[:nodejs][:paginate][:default]
    definitions[:paginate][:max] = node[:nodejs][:paginate][:max]
    definitions[:public] = node[:nodejs][:public_dir_path]
    definitions[:mongoUser] = node[:mongodb][:admin_user]
    definitions[:mongoPass] = password
    definitions[:mongoAdminDB] = "admin"
    definitions[:mongoReplSet] = node[:mongodb][:replicaset_name]
    
    
    local_env_dir = "#{doc_root}/config"
    local_env_file = "#{local_env_dir}/#{node[:nodejs][:env_file]}"
  
    directory local_env_dir do
          owner     username
          group     node[:setup][:group]
          mode      '755'
          recursive true
    end
    
    
    
    template local_env_file do
        source "env.json.erb"
        cookbook "setup"
        owner username
        group node[:setup][:group]
        mode 00644
        variables(:definitions => definitions)
    end
    
    customdefs = Hash.new
    customdefs[:mongoUser] = node[:mongodb][:admin_user]
    customdefs[:mongoPass] = password
    customdefs[:mongoAdminDB] = "admin"
    customdefs[:mongoReplSet] = node[:mongodb][:replicaset_name]
    
    
    template "#{local_env_dir}/custom-environment-variables.json" do
        source "env.json.erb"
        cookbook "setup"
        owner username
        group node[:setup][:group]
        mode 00644
        variables(:definitions => customdefs)
    end
    
    
    execute "restart #{name} service" do
      command "sleep 5"
      notifies :restart, resources(:service => name), :immediately
    end
end  
