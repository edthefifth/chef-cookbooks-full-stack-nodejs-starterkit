# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

node[:deploy].each do |application, deploy|
  

  if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
    Chef::Log.info("Skipping nodejs::service on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
    next
  end   

  if not deploy[:environment_variables].has_key?('nodejs')
    Chef::Log.info("Skipping nodejs::update for #{application}")
    next
  end    

  service application do
    supports :restart => true, :reload => false, :status => true
    action :nothing
  end
  

  
end  
