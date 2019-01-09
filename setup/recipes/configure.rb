# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting setup::configure")


  
   

  node[:setup][:module_recipes].each do |recipe|
    include_recipe "#{recipe}"
  end
  
  db_server_name,db_server = node[:opsworks][:layers]["main-db"][:instances].first;
  main_ip = db_server[:private_ip]
  elasticsearch_array = []
  connection = ''
  connection_iter=0;
  unixid , user =  node["ssh_users"].first
  
  node[:opsworks][:layers]["main-db"][:instances].each do |db_server_name,db_server|
    if connection_iter == 0
      connection+="#{db_server[:private_ip]}:#{node[:main][:port]}"
    else
      connection+=",#{db_server[:private_ip]}:#{node[:main][:port]}"
    end
    connection_iter+=1
  end
  
  node[:opsworks][:layers]["backup-db"][:instances].each do |db_server_name,db_server|
    if connection_iter == 0
      connection+="#{db_server[:private_ip]}:#{node[:backup][:port]}"
    else
      connection+=",#{db_server[:private_ip]}:#{node[:backup][:port]}"
    end
    connection_iter+=1
  end
  
  
      
  if node[:opsworks][:layers].key?("elasticsearch")
    node[:opsworks][:layers]['elasticsearch'][:instances].each do |e_name,e_server|
      elasticsearch_array << "#{e_server[:private_ip]}:#{node[:elasticsearch][:http][:port]}"
    end
  end
  
  bash "install main-db to /etc/hosts" do
    user "root"
    code <<-EOH
      echo "#{main_ip}  main-db" >> /etc/hosts
    EOH
    not_if "grep main-db /etc/hosts"
  end
  
  
  
  
  
  definitions = Hash.new
  
  definitions[:private_ip] = node[:opsworks][:instance][:private_ip];
  definitions[:mongo_connection] = connection
  definitions[:mongo_main] = main_ip
  definitions[:elasticsearch] = elasticsearch_array

  template node[:setup][:env_file] do
      source "env.json.erb"
      cookbook "setup"
      owner node['nginx']['user']
      group node[:setup][:group]
      mode 00640
      variables(:definitions => definitions)
  end
  

