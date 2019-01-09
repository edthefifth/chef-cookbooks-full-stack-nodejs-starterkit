#
# Cookbook Name:: nginx
# Definition:: nginx_node_instance
define :nginx_node_instance,:home=>"/vol", :user=>"root", :group=>"root", \
 :domain=>"localhost", :access_log=>"/vol/nginx/log/", \
 :node_urls=>["localhost:45555"], :web_host=>'localhost', :web_port=>80,:doc_root=>'/vol/www' , :destination=>'/vol/nginx', \
 :init_script=>nil, :volumes=>[], :run_exec=>[], :add_exec=>[], :dependencies=>[], :load_balance_method=>false,:copy=>true, \
 :max_fails=>3, :request_timeout=>10, :local_web_port=>nil, :has_static=>true, :run_options=>[] \
do

  name = params[:name]
  home = params[:home]
  user = params[:user]
  group = params[:group] || user
  domain = params[:domain]
  node_urls = params[:node_urls]
  web_host = params[:web_host]
  web_port = params[:web_port]
  local_web_port = params[:local_web_port] || web_port
  access_log = params[:access_log]
  destination = params[:destination]
  volumes = params[:volumes]
  run_exec = params[:run_exec]
  add_exec = params[:add_exec]
  dependencies = params[:dependencies]
  load_balance_method = params[:load_balance_method]
  run_options = params[:run_options]
  copy = params[:copy]
  timeout = params[:request_timeout]
  max_fails = params[:max_fails]
  doc_root = params[:doc_root]
  has_static = params[:has_static]
  
  dir = home
  
  dest_dir = "#{destination}/#{name}"
  
  #node_urls.each do |node_url|
  #  len = (node_url.index(":")-1) || node_url.length;
  #  node_host = node_url[0..len]
  #  dns_command = "echo #{node_host} #{domain} >>/etc/hosts"
  #  Chef::Log.info("updated /etc/hosts with #{node_host} #{domain}");
  #  execute "update /etc/hosts with #{domain} with #{node_host}" do
  #    user  "root"
  #    group "root"
  #    command dns_command
  #  end
  #end    
  
  directory "#{dir}/nginx" do
    owner     user['name']
    group     user['name']
    mode      '755'
    recursive true
    not_if { ::File.directory?("#{dir}/nginx") }
  end

  
 
  execute "create info.json" do
    user  "root"
    group "root"
    command "echo {node_urls:#{node_urls.to_json},web_port:#{web_port},web_host:#{web_host} > #{dir}/info.json";
  end  
   
    
  directory "#{dir}/log" do
    owner     user
    group     group
    mode      '755'
    recursive true
    not_if { ::File.directory?("#{dir}/log") }
  end
  
  
  
  config_file = "#{dir}/nginx/nginx.conf"
  env_file = "#{dir}/nginx/nginx.env" 
  init_script =  "#{dir}/nginx/init.sh" 
  command = "/usr/sbin/nginx -c #{dest_dir}/nginx/nginx.conf"
  log_dir = "/vol/log/nginx/#{name}"
  
  directory "#{log_dir}" do
    owner     user
    group     group
    mode      '755'
    recursive true
    not_if { ::File.directory?("#{log_dir}") }
  end 
  
  template config_file do
        source "nginx.node.erb"
        owner user
        group group
        mode 00644
        cookbook "nginx"
        variables(
          :domain => domain,
          :node_urls => node_urls,
          :web_port => local_web_port,
          :log_dir=>log_dir,
          :static_home=>doc_root,
          :load_balance_method=>load_balance_method,
          :timeout=>timeout,
          :max_fails=>max_fails,
          :has_static=>has_static
       )
   end
   
    
    
   template env_file do
        source "nginx.sysconfig.erb"
        owner user
        group group
        mode 00644
        cookbook "nginx"
        variables(
          :config_file => config_file
       )
   end  
    
   template init_script do
        source "nginx.init.erb"
        owner user
        group group
        mode 00755
        cookbook "nginx"
        variables(
          :env_file => env_file
       )
   end
   

  
    group = node[:setup][:group]
    ssh_user = node[:setup][:ssh_user]
    ssh_host = node[:setup][:ssh_host]
    lib = node[:setup][:home_dir]
    
    unixid , user =  node["ssh_users"].first;
    
    
    
    
    
end
