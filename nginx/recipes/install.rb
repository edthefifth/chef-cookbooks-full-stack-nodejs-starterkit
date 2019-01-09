# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


node[:opsworks][:instance][:layers].each do |layer| 

  _layer = layer.downcase
  
  if not _layer.include?("-lb")
    Chef::Log.info("Skipping nginx::install on #{layer}")
  end  
    
  Chef::Log.info("Installing nginx on #{layer}")
  
  include_recipe "yum-epel"
  
  include_recipe "nginx::package"

  include_recipe 'nginx::commons'

  node['nginx']['default']['modules'].each do |ngx_module|
    include_recipe "nginx::#{ngx_module}"
  end
  
  
end    

