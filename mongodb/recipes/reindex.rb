# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


mongo_password = node[:deploy][:main_db][:environment_variables][:password_value]
mongo_user = node[:deploy][:main_db][:environment_variables][:user_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db"
      Chef::Log.info("Skipping mongo::reindex for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|
    
    if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
      Chef::Log.info("Skipping mongo::configure on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
      next
    end

    if deploy[:environment_variables][:layer] != "main-db"
        Chef::Log.info("Skipping mongo::configure for application #{application} on layer #{layer}")
        next
    end
    
    
    execute "wait for mongo on #{node[:main][:url]}:#{node['main']['port']} to come up" do
      user node[:mongodb][:user]
      command "until echo 'exit' | /usr/bin/mongo --host #{node[:main][:url]}:#{node[:main][:port]} -u '#{node[:mongodb][:admin_user]}' -p '#{mongo_password}' --authenticationDatabase=admin --quiet; do sleep 10s; done"
    end

    cookbook_file "#{node['mongodb']['defaults_dir']}/mongodb.rebuild.indexes.js" do
      cookbook "setup"
      source "config-api-indexes.js"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode '0755'
    end
    
    execute "setup config api indexes #{node[:mongodb][:replicaset_name]}" do
      command "/usr/bin/mongo --host #{node[:main][:url]}:#{node[:main][:port]} -u '#{node[:mongodb][:admin_user]}' -p '#{mongo_password}' --authenticationDatabase=admin #{node['mongodb']['defaults_dir']}/mongodb.rebuild.indexes.js"
      Chef::Log.info "Indexes rebuilt"
    end
    
  end
end  