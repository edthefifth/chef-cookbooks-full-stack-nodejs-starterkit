# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

include_recipe "nodejs::service"


node[:deploy].each do |application, deploy|
    if not deploy[:environment_variables].has_key?('nodejs')
        Chef::Log.info("Skipping nodejs::deploy for #{application}")
        next
    end 
    
      
    node[:opsworks][:instance][:layers].each do |layer|
      
      if layer != deploy[:environment_variables][:layer]
        Chef::Log.info("Skipping nodejs::deploy for layer #{layer}")
        next
      end  
    
      name = deploy[:environment_variables][:name]
      port = deploy[:environment_variables][:port]

      dir = "/vol/#{name}"
      nginx_name = "nginx"
      nginx_dir = "#{dir}/#{nginx_name}"
      nginx_log_dir = "#{node[:setup][:log_home]}/nginx"
      nodejs_log_dir = "#{node[:setup][:log_home]}/nodejs"
      
      local_port = deploy[:environment_variables][:proxy_port]
      start = deploy[:environment_variables][:nodejs]
      lib_dir = deploy[:environment_variables][:dir]
      code_dir = "#{lib_dir}/#{deploy[:document_root]}"
      config_file = "#{nginx_dir}/nginx.conf"
      env_file = "#{nginx_dir}/nginx.env" 
      init_script =  "#{nginx_dir}/init.sh" 
      
      use_proxy = deploy[:environment_variables][:use_proxy] || false
      lowercase_name = name.downcase
      service_name = "#{lowercase_name}.service" 
      nginx_service = "#{lowercase_name}NGINX"
      nginx_log = "#{nginx_log_dir}/#{nginx_service}.log"
      nginx_err_log = "#{nginx_log_dir}/#{nginx_service}.err"
      nginx_command = "/usr/sbin/nginx -c #{nginx_dir}/nginx.conf"
      nginx_service_name = "#{nginx_service}.service"
      unixid , user =  node["ssh_users"].first
      
      if node[:nodejs][:env] == 'dev'
        username = user[:name]
      else
        username = node['nginx']['user']
      end
      
      directory code_dir do
          owner     username
          group     node[:setup][:group]
          mode      '755'
          recursive true
      end

      directory "#{nodejs_log_dir}" do
        owner     username
        group     node[:setup][:group]
        mode      '775'
        recursive true
        not_if { ::Dir.exists?("#{nodejs_log_dir}") }
      end
      


      if use_proxy || use_proxy == "1"




        directory "#{nginx_dir}/#{name}" do
          owner     username
          group     node[:setup][:group]
          mode      '755'
          recursive true
          not_if { ::Dir.exists?("#{nginx_dir}/#{name}}") }
        end


        directory "#{nginx_log_dir}" do
          owner     username
          group     node[:setup][:group]
          mode      '755'
          recursive true
          not_if { ::Dir.exists?("#{nginx_log_dir}") }
        end

        


        apps = Hash.new
        apps[name]=deploy[:domains].first
        application

        template config_file do
            source"nginx.server.node.erb"
            owner username
            group node[:setup][:group]
            mode 00644
            cookbook "nginx"
            variables(
              :apps=>apps,
              :node_urls => ["127.0.0.1:#{local_port}"],
              :local_port=>local_port,
              :web_port => port,
              :log_dir=>"#{nginx_log_dir}",
              :lib_dir=>code_dir,
              :load_balance_method=>false,
              :timeout=>3600,
              :max_fails=>5,
              :has_static=>true
           )
       end
       
       #template env_file do
       #     source "nginx.sysconfig.erb"
       #     owner user[:name]
       #     group group
       #     mode 00644
       #     cookbook "nginx"
       #     variables(
       #       :config_file => "#{nginx_dir}/nginx.conf"
       #    )
       #end  

       
       #template init_script do
       #     source "nginx.init.erb"
       #     owner user[:name]
       #     group node[:setup][:group]
       #     mode 00755
       #     cookbook "nginx"
       #     variables(
       #       :env_file => env_file
       #    )
       #end
       #
      
       execute "ln -s #{config_file} #{node[:nginx][:dir]}/conf.d/#{name}.nginx.conf" do
          user "root"
          command "ln -s #{config_file} #{node[:nginx][:dir]}/conf.d/#{name}.nginx.conf"
          notifies :restart, resources(:service => "nginx"), :immediately
       end

      end

      

       template  "#{node[:nodejs][:init_dir]}/#{service_name}" do
          source "node.systemd.erb"
          owner "root"
          group "root"
          mode 00644
          cookbook "nodejs"
          variables(
              :name => lowercase_name,
              :dir=> code_dir,
              :app => "src/#{start}",
              :port => local_port,
              :user => username,
              :env => node[:nodejs][:env]
          )
       end

    end
end
include_recipe "nodejs::install_codebase"
include_recipe "nodejs::update"