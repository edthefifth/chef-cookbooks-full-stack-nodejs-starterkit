# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db"
      Chef::Log.info("Skipping mongo::load_backup for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|
    
    if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
      Chef::Log.info("Skipping mongo::load_backup on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
      next
    end

    if deploy[:environment_variables][:layer] != "main-db"
        Chef::Log.info("Skipping mongo::load_backup for application #{application} on layer #{layer}")
        next
    end

    include_recipe "mongodb::backup_deploy"
    include_recipe "mongodb::backup_configure"
    
  end
end  
