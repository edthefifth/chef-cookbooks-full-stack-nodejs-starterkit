# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

include_recipe 'nginx::commons'

node['nginx']['default']['modules'].each do |ngx_module|
  include_recipe "nginx::#{ngx_module}"
end


name = "nginx_redirect"
service_name = name 
service_path ="/etc/init.d/" + service_name
dir = "/vol/#{name}"
config_file = "#{dir}/nginx/nginx.conf"


directory "#{dir}/nginx" do
    owner     "root"
    group     "root"
    mode      '755'
    recursive true
    not_if { ::File.directory?("#{dir}/nginx") }
end


env_file = "#{dir}/nginx/nginx.env" 
init_script =  "#{dir}/nginx/init.sh" 

template config_file do
      source "nginx.redirect.erb"
      owner "root"
      group "root"
      mode 00644
      cookbook "nginx"
      variables(
        :listen_port=>8301,
        :log_dir=>dir
     )
 end
 
template env_file do
        source "nginx.sysconfig.erb"
        owner "root"
        group "root"
        mode 00644
        cookbook "nginx"
        variables(
          :config_file => config_file
       )
   end  
    
   template service_path do
        source "nginx.init.erb"
        owner "root"
        group "root"
        mode 00755
        cookbook "nginx"
        variables(
          :env_file => env_file
       )
   end
   
 



  bash "Register " +  service_name do
        user "root"
        code <<-EOH
          sudo service #{service_name} start 
        EOH
  end
