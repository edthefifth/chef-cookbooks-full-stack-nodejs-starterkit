# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting mongodb::security")

require 'securerandom'

password = node[:deploy][:main_db][:environment_variables][:password_value]
  
key = node[:deploy][:main_db][:environment_variables][:key_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongo::security for layer #{layer}")
      next
  end 
  

  node[:deploy].each do |application, deploy|


    Chef::Log.info("deploying mongodb::security on #{deploy[:environment_variables][:layer]}")

    if deploy[:environment_variables][:layer] == "main-db" && layer == deploy[:environment_variables][:layer]
      
      config_file = node['main']['configfile']
      name = node['main']['name']
      port = node['main']['port']
      logpath = node['main']['logpath']
      logfile = "#{logpath}/#{name}.log"
      dbpath = node['main']['dbpath']
      
      
      
    elsif deploy[:environment_variables][:layer] == "arbiter-db" && layer == deploy[:environment_variables][:layer]
      
      config_file = node['arbiter']['configfile']
      name = node['arbiter']['name']
      port = node['arbiter']['port']
      logpath = node['arbiter']['logpath']
      logfile = "#{logpath}/#{name}.log"
      dbpath = node['arbiter']['dbpath']
    
    elsif deploy[:environment_variables][:layer] == "backup-db" && layer == deploy[:environment_variables][:layer]
      
      config_file = node['backup']['configfile']
      name = node['backup']['name']
      port = node['backup']['port']
      logpath = node['main']['logpath']
      logfile = "#{logpath}/#{name}.log"
      dbpath = node['backup']['dbpath']
      
    else
      Chef::Log.info("Skipping mongo::security for #{deploy[:environment_variables][:layer]} on #{layer}");
      next
    end  
    
    execute "mkdir -p #{logpath}" do
      command "mkdir -p #{logpath}"
      not_if { ::Dir.exists?(logpath)}
    end
    
    include_recipe "mongodb::service_#{deploy[:environment_variables][:replica_role]}"
    
    template "#{config_file}" do
      action :create
      source "mongod.conf.erb"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode "0644"
      variables(
        "port" => port,
        "logpath" => logfile,
        "dbpath" => dbpath,
        "pidfile" =>  "#{node[:mongodb][:pidpath]}/#{name}.pid",
        "authbool"=>"disabled"
      )
      notifies :restart, resources(:service => "#{name}"), :immediately
    end

    


    if deploy[:environment_variables][:layer] == "main-db" && layer == deploy[:environment_variables][:layer]

      execute "wait for mongo on #{node[:opsworks][:instance][:private_ip]}:#{port} to come up" do
        command "until echo 'exit' | /usr/bin/mongo local --host #{node[:opsworks][:instance][:private_ip]}:#{port} --quiet; do sleep 10s; done"
      end

      execute "#{node[:opsworks][:instance][:private_ip]}:#{port} dropuser user" do
        command "/usr/bin/mongo admin --host #{node[:opsworks][:instance][:private_ip]}:#{port} --eval 'db.dropUser(\"#{node[:mongodb][:admin_user]}\")'"
        ignore_failure true
        not_if { ::File.exists?(node[:mongodb][:passwordfile])}
      end


      execute "#{node[:opsworks][:instance][:private_ip]}:#{port} create admin user" do
        command "/usr/bin/mongo admin --host #{node[:opsworks][:instance][:private_ip]}:#{port} --eval 'db.createUser({user:\"#{node[:mongodb][:admin_user]}\",pwd:\"#{password}\",roles:[{role:\"root\",db:\"admin\"}]})'"
        not_if { ::File.exists?(node[:mongodb][:passwordfile])}
      end

    end





    template "#{node[:mongodb][:keyfile]}" do
      action :create
      source "keyfile.erb"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode "0400"
      variables(
        "keyfile"=>key
      )
      #notifies :restart, "service[#{name}]"
      not_if { ::File.exist?(node[:mongodb][:keyfile])}
    end


    template "#{config_file}" do
      action :create
      source "mongod.conf.erb"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode "0644"
      variables(
        "port" => port,
        "logpath" => logfile,
        "dbpath" => dbpath,
        "replicaset_name" => node['mongodb']['replicaset_name'],
        "pidfile" =>  "#{node[:mongodb][:pidpath]}/#{name}.pid",
        "authbool"=>"enabled",
        "keyfile"=>node[:mongodb][:keyfile],
        'ip'=>node[:opsworks][:instance][:private_ip]
      )
      notifies :restart, "service[#{name}]", :immediately
    end
    
    
  end
end  


pwgroup = node[:setup][:group]


template "#{node[:mongodb][:passwordfile]}" do
  source "env.json.erb"
  cookbook "setup"
  owner "root"
  group pwgroup
  mode "0440"
  variables(:definitions => {:mongoUser=>node[:mongodb][:admin_user],:mongoPassword=>password})
end

