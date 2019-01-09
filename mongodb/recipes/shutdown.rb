# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting mongodb::shutdown")
password = node[:deploy][:main_db][:environment_variables][:password_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongo::configure for layer #{layer}")
      next
  end


    
  Chef::Log.info("shutting down and reconfiguring mongo by removing mongo for layer #{layer}")

  rs_nodes = []

  url = nil
  port = node[:main][:port]
  main_servers = node[:opsworks][:layers]["main-db"][:instances]
  iter=0
  main_servers.each do |key,server|
      url = server[:private_ip]
      port = node[:main][:port]
      rs_nodes << "#{url}:#{port}"
  end

  backup_servers = main_servers = node[:opsworks][:layers]["backup-db"][:instances]
  backup_servers.each do |key,server|
    url = server[:private_ip]
    port = node[:backup][:port]
    rs_nodes << "#{url}:#{port}"
  end
  
  arbiter_servers = main_servers = node[:opsworks][:layers]["arbiter-db"][:instances]
 arbiter_servers.each do |key,server|
    url = server[:private_ip]
    port = node[:arbiter][:port]
    rs_nodes << "#{url}:#{port}"
  end
  


  if layer == "main-db" 
    role_port = node["main"]["port"]
    service_name = "mongod"
  elsif layer == "arbiter-db" 
    role_port = node["arbiter"]["port"]
    service_name = "mongoa"
  elsif layer == "backup-db" 
    role_port = node["backup"]["port"]
    service_name = "mongob"
  else
    Chef::Log.info("Skipping mongo::deploy main for #{layer}");
    next
  end 

  service service_name do
    supports :status => true, :restart => true
    action :stop
  end

  member_url = "#{node[:opsworks][:instance][:private_ip]}:#{role_port}"

  template "#{node['mongodb']['defaults_dir']}/reconfig_members.js" do
    action :create
    source "reconfig_members.js.erb"
    owner node[:mongodb][:user]
    group node[:mongodb][:group]
    mode '0755'
    variables( :member_url => member_url )
  end


  rs_nodes.each do |rs_node|
    execute "reconfig #{rs_node} to remove #{service_name} on #{member_url}" do
      command "/usr/bin/mongo --host #{rs_node} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin #{node['mongodb']['defaults_dir']}/reconfig_members.js"
      ignore_failure  true
      Chef::Log.info "Removing #{member_url} from replicaset"
      only_if { "mongostat --host=#{rs_node} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --noheaders -n 1 | grep 'PRI'"}
    end
  end

   

end
