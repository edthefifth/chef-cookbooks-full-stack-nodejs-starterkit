# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

include_recipe "selinux::disabled"
include_recipe "nginx::service"

node[:deploy].each do |application, deploy|
  

  
  
  if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
    Chef::Log.info("Skipping nginx::configure on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
    next
  end
  
  
  
  execute "restart nginx service" do
      user "root"
      command "sleep 30"
      notifies :restart, resources(:service => "nginx")
  end
  
  
  
end
