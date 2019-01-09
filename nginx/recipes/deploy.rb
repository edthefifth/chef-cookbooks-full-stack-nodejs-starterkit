# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting nginx::deploy")

include_recipe "nginx::service"

node[:deploy].each do |application, deploy|
  

  
  
  if not node[:opsworks][:instance][:layers].include?(deploy[:environment_variables][:layer])
    Chef::Log.info("Skipping nginx::deploy on #{node[:opsworks][:instance][:hostname]} because layer #{deploy[:environment_variables][:layer]} is not installed on this instance")
    next
  end 
  
  
  if not deploy[:document_root]
    Chef::Log.info("Skipping nginx::deploy on #{node[:opsworks][:instance][:hostname]} for #{application} because document_root is not set")
    next
  end
  
  if not node[:opsworks][:layers][application].key?("elb-load-balancers")
    Chef::Log.info("Skipping nginx::deploy #{application} does not have load balancers attached")
    next
  end
  
  Chef::Log.info("deploying nginx for #{application}")
  
  unixid , user =  node["ssh_users"].first
  
  node_urls= []
  
  home_dir = '/vol/www/ContentSite'
  
  doc_root = home_dir+"/"+deploy[:document_root]
  
  
  case application
  when "web_lb","web"
    
    
    node[:opsworks][:layers]["web"][:instances].each do |instance_name,instance|
      host = instance[:private_ip]
      port = node[:deploy]["web_app"][:environment_variables][:serviceport]
      node_urls << "#{host}:#{port}"
    end
    
  when "api_lb","api"
    
    node[:opsworks][:layers]["api"][:instances].each do |instance_name,instance|
      host = instance[:private_ip]
      port = node[:deploy]["api_app"][:environment_variables][:serviceport]
      node_urls << "#{host}:#{port}"
    end
  
  when "adminui_lb","adminui"
    
    node[:opsworks][:layers]["adminui-app"][:instances].each do |instance_name,instance|
      host = instance[:private_ip]
      port = node[:deploy]["adminui_app"][:environment_variables][:serviceport]
      node_urls << "#{host}:#{port}"
    end
  
 
  
  else
    Chef::Log.info("Skipping nginx::deploy for #{application} because it is not defined");
    next
  end
  
  nginx_name = application
  nginx_home = "/vol/#{nginx_name}"
  
  
  directory "#{nginx_home}" do
    owner     user['name']
    group     user['name']
    mode      '755'
    recursive true
    not_if { ::File.directory?("#{nginx_home}") }
  end
  

  
  
  nginx_run_exec = ["yum install -y nginx"]
  destination= "/vol"
  nginx_volumes = ["#{nginx_home}"]
  nginx_run_opts = ["-d","-v #{nginx_home}:#{destination}/#{nginx_name}:rw","--name #{nginx_name}"]
  nginx_node_instance nginx_name do
    user        user['name']
    group       "developers"
    web_host    node[:opsworks][:instance][:ip]
    web_port    deploy[:environment_variables][:serviceport]
    node_urls   node_urls
    home        nginx_home
    run_exec    nginx_run_exec
    volumes     nginx_volumes
    run_options nginx_run_opts
    destination destination
    domain      nginx_name
    doc_root    doc_root
  end
  
end
