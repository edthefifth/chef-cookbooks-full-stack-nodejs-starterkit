# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

password = node[:deploy][:main_db][:environment_variables][:password_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db"
      Chef::Log.info("Skipping mongo::configure for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|
    
    if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
      Chef::Log.info("Skipping mongo::fix_primary on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
      next
    end

    
    ##
    # Only for Backup and Arbiter
    ##
    
    if deploy[:environment_variables][:layer] != "main-db" && deploy[:environment_variables][:layer] != "main-db"
        Chef::Log.info("Skipping mongo::fix_primary for application #{application} on layer #{layer}")
        next
    end
    
    
    this_url = node[:opsworks][:instance][:private_ip]
    main_servers = node[:opsworks][:layers]["main-db"][:instances]
    iter=0
    main_servers.each do |key,server|
      
      if iter === 0
        node.default[:main][:url] = server[:private_ip]
        main_url = server[:private_ip]
      end
      
      url = "#{server[:private_ip]}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['main']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo #{url}:#{node['main']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    arbiter_servers = node[:opsworks][:layers]["arbiter-db"][:instances]
    iter=0
    arbiter_servers.each do |key,server|
      
      if iter === 0
        node.default[:arbiter][:url]=server[:private_ip]
      end
      
      url = "#{server[:private_ip]}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['arbiter']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo #{url}:#{node['arbiter']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    backup_servers = node[:opsworks][:layers]["backup-db"][:instances]
    iter=0
    backup_servers.each do |key,server|
      
      if iter === 0
        node.default[:backup][:url]=server[:private_ip]
      end
      
      url =  "#{server[:private_ip]}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['backup']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo #{url}:#{node['backup']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    
    if this_url == node[:main][:url]
        

          
      
          _next =  0
          _priority = 100
          _url = "#{node['main']['url']}:#{node['main']['port']}"
          execute "add main back to replset if backup is primary" do
                user "root"
                command "/usr/bin/mongo #{node['backup']['url']}:#{node['backup']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --eval 'printjson(rs.add({\"_id\":#{_next},\"host\":\"#{_url}\",\"priority\":#{_priority}}))' >> /vol/fix_main_repl.out"
                only_if "/usr/bin/mongo #{node['backup']['url']}:#{node['backup']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1' "
                Chef::Log.info "Adding main to replicaset with _id:#{_next} and priority:#{_priority}"
          end
          
          execute "add main back to replset if arbiter is primary" do
                user "root"
                command "/usr/bin/mongo #{node['arbiter']['url']}:#{node['arbiter']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --eval 'printjson(rs.add({\"_id\":#{_next},\"host\":\"#{_url}\",\"priority\":#{_priority}}))' >> /vol/fix_main_repl.out"
                only_if "/usr/bin/mongo #{node['arbiter']['url']}:#{node['arbiter']['port']} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1'"
                Chef::Log.info "Adding main to replicaset with _id:#{_next} and priority:#{_priority}"
          end
      
          
          
    end      
  end
end

