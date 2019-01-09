# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

define :redhat_mongodb_instance, :mongodb_type => "mongod" , :port => 27017 , \
    :logpath => "/vol/log/mongod", :dbpath => "/vol/lib/mongod", :configfile => "/etc/mongod.conf" do
    
  name = params[:name]
  type = params[:mongodb_type]
  
  port = params[:port]

  logpath = params[:logpath]
  logfile = "#{logpath}/#{name}.log"
  
  dbpath = params[:dbpath]
  
  configfile = params[:configfile]
  
  service_name = "#{node['mongodb']['init_dir']}/#{name}.service"
  
  Chef::Log.info "Deploying #{name} service"
  
   # log dir [make sure it exists]
  directory logpath do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
    not_if { ::Dir.exists?(logpath)}
    Chef::Log.info "Creating log directory #{logpath} for user #{node[:mongodb][:user]}"
  end
  
  bash "adjust #{logpath} permissions for #{name}" do
        user "root"
        code <<-EOH
          chown #{node[:mongodb][:user]}:#{node[:mongodb][:group]} #{logpath}
        EOH
  end
  
  
  directory "#{node[:mongodb][:pidpath]}" do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
    not_if { ::Dir.exists?(node[:mongodb][:pidpath])}
    Chef::Log.info "Creating pid directory #{node[:mongodb][:pidpath]} for user #{node[:mongodb][:user]}"
  end
  
  bash "adjust #{node[:mongodb][:pidpath]} permissions for #{name}" do
        user "root"
        code <<-EOH
          chown #{node[:mongodb][:user]}:#{node[:mongodb][:group]} #{node[:mongodb][:pidpath]}
        EOH
  end
  

  # dbpath dir [make sure it exists]
  directory dbpath do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
    Chef::Log.info "Creating db directory #{dbpath} for user #{node[:mongodb][:user]}"
  end
  
  bash "adjust #{dbpath} permissions for #{name}" do
        user "root"
        code <<-EOH
          chown #{node[:mongodb][:user]}:#{node[:mongodb][:group]} #{dbpath}
        EOH
  end
  
  bash "adjust #{name} readahead" do
     user "root"
     code <<-EOH
       VOLBLOCK=`df --output=source /vol | tail -n +2`
       blockdev --setra 256 "$VOLBLOCK"
     EOH
  end

  
  template service_name do
      action :create
      source "mongod.service.erb"
      group "root"
      owner "root"
      mode "0644"
      variables({
         :name => name,
         :user => node[:mongodb][:user],
         :group => node[:mongodb][:group],
         :config =>configfile,
         :pidfile => "#{node[:mongodb][:pidpath]}/#{name}.pid",
         :lib => dbpath
      })   
      Chef::Log.info "Creating service #{service_name}"
  end  
  
  
  template "#{configfile}" do
      action :create
      source "mongod.conf.erb"
      owner node[:mongodb][:user]
      group node[:mongodb][:group]
      mode "0644"
      variables(
        "port" => port,
        "logpath" => logfile,
        "dbpath" => dbpath,
        "replicaset_name" => node['mongodb']['replicaset_name'],
        "pidfile" =>  "#{node[:mongodb][:pidpath]}/#{name}.pid",
        "authbool"=>"disabled"
      )
      Chef::Log.info "Creating #{configfile}"
  end
  
  
  
  
  
  
  
  # Add Log rotation
  template "/etc/logrotate.d/#{name}_log" do
    cookbook "rsyslog"
    source "mongodb_log.erb"
    backup false
    owner node['rsyslog']['user']
    group node['rsyslog']['group']
    mode 0644
    variables(
            :path => logpath,
            :pattern => "#{name}.log",
            :user => node[:mongodb][:user],
            :pid_file => "#{node[:mongodb][:pidpath]}/#{name}.pid"
          )
  end
  
  bash "turn #{name} transparent page enabled and defrag to never" do
        user "root"
        code <<-EOH
          echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
          echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
        EOH
  end
  
  
  
  
  if name == 'mongoa'
    include_recipe "mongodb::service_arbiter";
  elsif name == 'mongob'
    include_recipe "mongodb::service_backup";
  else
    include_recipe "mongodb::service_main";
  end 
  
  execute "start and enable #{name}" do
    command "sleep 5"
    notifies :start, resources(:service => name), :immediately
  end
  
  
  
  
  
end
