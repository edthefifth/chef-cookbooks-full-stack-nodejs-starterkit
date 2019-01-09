# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

password = node[:deploy][:main_db][:environment_variables][:password_value]

  node[:opsworks][:instance][:layers].each do |layer|

    if layer != "main-db"
      Chef::Log.info("Skipping mongo::init_repl for layer #{layer}")
      next
    end
    
    node[:deploy].each do |application, deploy|
    
      if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
        Chef::Log.info("Skipping mongo::init_repl on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
        next
      end

      if deploy[:environment_variables][:layer] != "main-db" 
          Chef::Log.info("Skipping mongo::init_repl for application #{application} on layer #{layer}")
          next
      end
      this_url = node[:opsworks][:instance][:private_ip]
      main_url = nil
      this_port = node['main']['port'];
      name = node['main']['name']
      
      main_servers = node[:opsworks][:layers]["main-db"][:instances]
      main_servers.each do |key,server|
        
       
        node.default[:main][:url] = server[:private_ip]
        main_url = server[:private_ip]
        break
        
      end
      
      

      include_recipe "mongodb::service_#{deploy[:environment_variables][:replica_role]}"
        

        template "#{node['mongodb']['defaults_dir']}/setup_replset.js" do
          action :create
          source "setup_replset.js.erb"
          owner node[:mongodb][:user]
          group node[:mongodb][:group]
          mode '0755'
          variables({ :mongo_replset => node['mongodb']['replicaset_name'],
                      :main_port => node['main']['port'],
                      :main_url => main_url
          })  
          not_if { ::File.exists?(node[:mongodb][:passwordfile])}
          not_if "echo 'rs.status()' | /usr/bin/mongo --host #{this_url}:#{this_port} --quiet | grep -q 'PRIMARY'"
          
        end 
      
     
      

        # ----- configure the repl set
        execute "setup replset #{node[:mongodb][:replicaset_name]}" do
          command "/usr/bin/mongo --host #{this_url}:#{this_port} #{node['mongodb']['defaults_dir']}/setup_replset.js"
          not_if { ::File.exists?(node[:mongodb][:passwordfile])}
          not_if "echo 'rs.status()' | /usr/bin/mongo --host #{this_url}:#{this_port} --quiet | grep -q 'PRIMARY'"
          notifies :restart, resources(:service => "#{name}"), :immediately
          Chef::Log.info "Replica set node initialized"
        end
        
     
        
        # ----- wait for repl set
        execute "wait for replset #{node[:mongodb][:replicaset_name]} to init" do
          command "until echo 'exit' | mongostat --host=#{main_url} --noheaders -n 1 | grep 'PRI'; do sleep 10s; done"
          not_if { ::File.exists?(node[:mongodb][:passwordfile])}
          timeout 600
          Chef::Log.info "Waiting for repl to init"
        end
    end
  end

