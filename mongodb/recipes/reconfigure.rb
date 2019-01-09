node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongo::configure for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|
    
    if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
      Chef::Log.info("Skipping mongo::configure on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
      next
    end

    if deploy[:environment_variables][:layer] != "main-db" && deploy[:environment_variables][:layer] != "backup-db" && deploy[:environment_variables][:layer] != "arbiter-db"
        Chef::Log.info("Skipping mongo::configure for application #{application} on layer #{layer}")
        next
    end
    this_url = node[:opsworks][:instance][:private_ip]
    this_port = "27017"
    rs_nodes = []
    main_url = nil
    
    
    ##
    #  Get Main server IP
    ##
    
    main_servers = node[:opsworks][:layers]["main-db"][:instances]
    iter=0
    main_servers.each do |key,server|
      
      if iter === 0
        node.default[:main][:url] = server[:private_ip]
        main_url = server[:private_ip]
      end
      
      url = "#{server[:private_ip]}"
      
      rs_nodes << "#{server[:private_ip]}:#{node['main']['port']}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['main']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo #{url}:#{node['main']['port']}/local --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    ##
    #  Get Arbiter IPs
    ##
    
    arbiter_servers = node[:opsworks][:layers]["arbiter-db"][:instances]
    iter=0
    arbiter_servers.each do |key,server|
      
      if iter === 0
        node.default[:arbiter][:url]=server[:private_ip]
      end
      rs_nodes << "#{server[:private_ip]}:#{node['arbiter']['port']}"
      
      url = "#{server[:private_ip]}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['arbiter']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo #{url}:#{node['arbiter']['port']}/local --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    ##
    #  Get Backup IPs
    ##
    
    backup_servers = node[:opsworks][:layers]["backup-db"][:instances]
    iter=0
    backup_servers.each do |key,server|
      
      if iter === 0
        node.default[:backup][:url]=server[:private_ip]
      end
      rs_nodes << "#{server[:private_ip]}:#{node['backup']['port']}"
      
      url =  "#{server[:private_ip]}"
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['backup']['port']} to come up" do
        command "until echo 'exit' | /usr/bin/mongo --host #{url}:#{node['backup']['port']} --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end
    
    if this_url == node[:main][:url]
       this_port = node['main']['port']
    elsif this_url == node[:arbiter][:url]
       this_port = node['arbiter']['port']
    else
       this_port = node['backup']['port']
    end   
    
    ##
    # Refresh RS Configuration
    ##
    
    
      
    template "#{node['mongodb']['defaults_dir']}/reconfigure.js" do
      action :create
      source "reconfigure.erb"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode '0755'
      variables( :host => "#{node['main']['url']}:#{node['main']['port']}", :priority => 100)
    end

    execute "reconfig #{node['main']['url']} in replicaset for #{this_url}" do
      command "/usr/bin/mongo --host #{this_url}:#{this_port} #{node['mongodb']['defaults_dir']}/reconfigure.js"
      ignore_failure  true
      only_if "/usr/bin/mongo --host #{this_url}:#{this_port} --eval \"printjson(rs.status())\"  | grep -q 'not reachable'"
      only_if { this_url == node[:main][:url] || "mongostat --host=#{this_url}:#{this_port} --noheaders -n 1 | grep 'PRI'"}
    end
        
    
    if this_url == node[:main][:url]
    
        
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
          not_if "echo 'rs.status()' | /usr/bin/mongo --port #{node['main']['port']} --quiet | grep -q 'PRIMARY'"
          not_if "/usr/bin/mongo #{node['backup']['url']}:#{node['backup']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 2' "
          not_if "/usr/bin/mongo #{node['arbiter']['url']}:#{node['arbiter']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 2'"
          not_if "/usr/bin/mongo #{node['backup']['url']}:#{node['backup']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1' "
          not_if "/usr/bin/mongo #{node['arbiter']['url']}:#{node['arbiter']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1'"
        end



        # ----- configure the repl set
        execute "setup replset #{node[:mongodb][:replicaset_name]}" do
          command "/usr/bin/mongo --host #{node[:main][:url]}:#{node['main']['port']} #{node['mongodb']['defaults_dir']}/setup_replset.js"
          not_if "echo 'rs.status()' | /usr/bin/mongo --host #{node[:main][:url]}:#{node['main']['port']} --quiet | grep -q 'PRIMARY'"
          not_if "/usr/bin/mongo --host #{node['backup']['url']}:#{node['backup']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 2' "
          not_if "/usr/bin/mongo --host #{node['arbiter']['url']}:#{node['arbiter']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 2'"
          not_if "/usr/bin/mongo --host #{node['backup']['url']}:#{node['backup']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1' "
          not_if "/usr/bin/mongo --host #{node['arbiter']['url']}:#{node['arbiter']['port']} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1'"

          Chef::Log.info "Replica set node initialized"
        end

        __port = 27018
        __iter = 2
        rs_nodes.each do |url|

            if url === node['backup']['url']
              __port = 27019
              priority = 5
            else
              priority = 1
            end
            execute "add to replset #{url}" do
              user "root"
              command "/usr/bin/mongo --host #{node['main']['url']}:#{node['main']['port']} --eval 'printjson(rs.add({\"_id\":#{__iter},\"host\":\"#{url}\",\"priority\":#{priority}}))' >> /vol/add_repl.out"
              not_if "/usr/bin/mongo --host #{node['main']['url']}:#{node['main']['port']} --eval \"printjson(rs.conf())\" | grep '#{url}'"
              not_if "/usr/bin/mongo --host #{url}:#{__port} --eval \"printjson(rs.status())\"  | grep -q '\"myState\" : 1' "
              Chef::Log.info "Adding #{url} to replicaset with _id:#{__iter} and priority:#{priority}"
            end
            __iter = __iter + 1
        end
    end  
  end
end  