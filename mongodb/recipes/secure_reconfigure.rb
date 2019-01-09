require 'mixlib/shellout'

password = node[:deploy][:main_db][:environment_variables][:password_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongo::secure_reconfigure for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|
    
    if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
      Chef::Log.info("Skipping mongo::secure_reconfigure on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
      next
    end

    if deploy[:environment_variables][:layer] != "main-db" && deploy[:environment_variables][:layer] != "backup-db" && deploy[:environment_variables][:layer] != "arbiter-db"
        Chef::Log.info("Skipping mongo::secure_configure for application #{application} on layer #{layer}")
        next
    end
    this_url = node[:opsworks][:instance][:private_ip]
    this_port = "27017"
    rs_nodes = []
    main_url = nil
    
    mains = []
    arbiters = []
    backups = []
    
    ##
    #  Get Main server IP
    ##
    
    Chef::Log.info("Running mongo secure_reconfigure for  #{layer}");
    
    main_servers = node[:opsworks][:layers]["main-db"][:instances]
    iter=0
    main_servers.each do |key,server|
      
      if iter === 0
        node.default[:main][:url]=server[:private_ip]
      end
      

      
      url = "#{server[:private_ip]}:#{node['main']['port']}"
      
      rs_nodes << url
      
      execute "wait for mongo on #{url} to come up - secure reconfig" do
        command "until echo 'exit' | /usr/bin/mongo --host #{url} --quiet; do sleep 10s; done"
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
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['arbiter']['port']} to come up - secure reconfig" do
        command "until echo 'exit' | /usr/bin/mongo --host #{url}:#{node['arbiter']['port']} --quiet; do sleep 10s; done"
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
      
      
      execute "wait for mongo on #{server[:private_ip]}:#{node['backup']['port']} to come up - secure reconfig" do
        command "until echo 'exit' | /usr/bin/mongo --host #{url}:#{node['backup']['port']} --quiet; do sleep 10s; done"
      end

      iter = iter + 1  
    end

    if deploy[:environment_variables][:layer] == 'arbiter-db'
      this_port = node['arbiter']['port']
      name = node['arbiter']['name']
    elsif deploy[:environment_variables][:layer] == 'backup-db'
      this_port = node['backup']['port']
      name = node['backup']['name']
    else
      this_port = node['main']['port']
      name = node['main']['name']
    end  
    
    service "#{name}" do
      supports :restart => true, :reload => false, :status => true
      action :nothing
    end
    
    execute "Double check that mongostat is installed" do
      command "mongostat --version"
      notifies :restart, resources(:service => "#{name}"), :immediately
    end
    
    
        
    __this_url = "#{this_url}:#{this_port}"
    Chef::Log.info("Sending secure configuring from #{__this_url}");
    Chef::Log.info(rs_nodes);
    rs_nodes.each do |_url|
  
        
        
        

        secure_mongo_config "config #{_url} with #{__this_url}" do
          user        node[:mongodb][:user]
          group       node[:mongodb][:group]
          files_dir   node['mongodb']['defaults_dir']
          main_url    _url
          current_url __this_url
          password    password
          username    node[:mongodb][:admin_user]
          nodes       rs_nodes
        end

           
          
        
        
        

      
      
        
        
      end
    
      break # Only one iteration required
    
  end
end  