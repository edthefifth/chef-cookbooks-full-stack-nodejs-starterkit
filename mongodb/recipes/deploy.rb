# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting mongodb::deploy")

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db" && layer != "backup-db" && layer != "arbiter-db"
      Chef::Log.info("Skipping mongodb::deploy for layer #{layer}")
      next
  end 
  
  include_recipe "selinux::disabled"

  node[:deploy].each do |application, deploy|


    Chef::Log.info("deploying mongo on #{deploy[:environment_variables][:layer]}")

    if deploy[:environment_variables][:layer] == "main-db" && layer == deploy[:environment_variables][:layer]
      Chef::Log.info("Including mongodb::#{deploy[:environment_variables][:replica_role]} for layer #{layer}")
      include_recipe "mongodb::#{deploy[:environment_variables][:replica_role]}"
    elsif deploy[:environment_variables][:layer] == "arbiter-db" && layer == deploy[:environment_variables][:layer]
      Chef::Log.info("Including mongodb::#{deploy[:environment_variables][:replica_role]} for layer #{layer}")
      include_recipe "mongodb::#{deploy[:environment_variables][:replica_role]}"
    elsif deploy[:environment_variables][:layer] == "backup-db" && layer == deploy[:environment_variables][:layer]
      Chef::Log.info("Including mongodb::#{deploy[:environment_variables][:replica_role]} for layer #{layer}")
      include_recipe "mongodb::#{deploy[:environment_variables][:replica_role]}"
    else
      Chef::Log.info("Skipping mongodb::deploy #{deploy[:environment_variables][:replica_role]} for #{application} on #{layer}");
      next
    end    
    
    
  end
end  

#include_recipe "mongodb::upgrade_primary"
#include_recipe "mongodb::upgrade_secondary"
