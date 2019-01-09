# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting mongodb::install")

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongo::install for layer #{layer}")
      next
  end
  
    Chef::Log.info("Installing mongo on #{layer}")

  include_recipe "mongodb::10gen_repo"
  
  package node[:mongodb][:package_name] do
    action      :install
    retries     2
    retry_delay 30
  end
  
 
  
  redhat_mongodb_instance 'mongod' do
    mongodb_type "mongod"
    port         node['main']['port']
    logpath      node['main']['logpath']
    dbpath       node['main']['dbpath']
    configfile   node['main']['configfile']
  end
  
  execute "stop mongod initial" do
    command "sleep 5"
    notifies :stop, resources(:service => "mongod"), :immediately
  end
  
  
  
  
  
end  
