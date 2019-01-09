#
# Cookbook Name:: mongodb
# Definition:: mongodb
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

define :mongodb_instance, :mongodb_type => "mongod" , :action => [:enable,:start], :port => 27017 , \
    :logpath => "/var/log/mongodb", :dbpath => "/data", :configfile => "/etc/mongodb.conf", \
    :configserver => [], :replicaset => nil, :enable_rest => false, \
    :notifies => [] do
    
  #include_recipe "mongodb::default"
  
  name = params[:name]
  type = params[:mongodb_type]
  service_action = params[:action]
  service_notifies = params[:notifies]
  
  port = params[:port]

  logpath = params[:logpath]
  logfile = "#{logpath}/#{name}.log"
  
  dbpath = params[:dbpath]
  
  configfile = params[:configfile]
  configserver_nodes = params[:configserver]
  
  replicaset = params[:replicaset]
  if type == "shard"
    if replicaset.nil?
      replicaset_name = nil
    else
      # for replicated shards we autogenerate the replicaset name for each shard
      replicaset_name = "rs_#{replicaset['mongodb']['shard_name']}"
    end
  else
    # if there is a predefined replicaset name we use it,
    # otherwise we try to generate one using 'rs_$SHARD_NAME'
    begin
      replicaset_name = replicaset['mongodb']['replicaset_name']
    rescue
      replicaset_name = nil
    end
    if replicaset_name.nil?
      begin
        replicaset_name = "rs_#{replicaset['mongodb']['shard_name']}"
      rescue
        replicaset_name = nil
      end
    end
  end
  
  if !["mongod", "shard", "configserver", "mongos"].include?(type)
    raise "Unknown mongodb type '#{type}'"
  end
  
  if type != "mongos"
    daemon = "/usr/bin/mongod"
    configserver = nil
  else
    daemon = "/usr/bin/mongos"
    configserver = configserver_nodes.collect{|n| "#{n['fqdn']}:#{n['mongodb']['port']}" }.join(",")
  end
  
  # default file
  
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
    end
    

  
  # log dir [make sure it exists]
  directory logpath do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
    Chef::Log.info "Creating log directory #{logpath} for user #{node[:mongodb][:user]}"
  end
  
  bash "adjust #{logpath} permissions" do
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
    Chef::Log.info "Creating pid directory #{node[:mongodb][:pidpath]} for user #{node[:mongodb][:user]}"
  end
  
  bash "adjust #{node[:mongodb][:pidpath]} permissions" do
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
  
  bash "adjust #{dbpath} permissions" do
        user "root"
        code <<-EOH
          chown #{node[:mongodb][:user]}:#{node[:mongodb][:group]} #{dbpath}
        EOH
  end
  
  # service
  
  if name == 'mongoa'
    include_recipe "mongodb::service_arbiter";
  elsif name == 'mongod'
    include_recipe "mongodb::service_main";
  else
    include_recipe "mongodb::service_backup";
  end  
  
  case node['platform']
  when "centos","redhat","fedora"
    service_name = "#{node['mongodb']['init_dir']}/#{name}.service"
  else  
    service_name = "#{node['mongodb']['init_dir']}/#{name}"
  end
  
  case node['platform']
  when "amazon"  
    template service_name do
        action :create
        source node[:mongodb][:init_script_template]
        group node['mongodb']['root_group']
        owner "root"
        mode "0755"
        variables({
           :name => name,
           :user => node[:mongodb][:user],
           :group => node[:mongodb][:group],
           :config =>configfile,
           :pidfile => "#{node[:mongodb][:pidpath]}/#{name}.pid"
        })   
    end
    
  when "centos","redhat","fedora"
    
     bash "adjust mongo readahead" do
        user "root"
        code <<-EOH
          VOLBLOCK=`df --output=source /vol | tail -n +2`
          blockdev --setra 256 "$VOLBLOCK"
        EOH
     end
    
    template service_name do
        action :create
        source node[:mongodb][:init_script_template]
        group node['mongodb']['root_group']
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
    end
    
    
    
  else  
    upstart_init = "#{node['mongodb']['upstart_dir']}/#{name}.conf"
    
    execute "create #{service_name}" do
      user "root"
      command "ln -s /lib/init/upstart-job #{service_name}"
      not_if { ::File.exist?(service_name) }
    end
    
    template upstart_init do
        action :create
        source "upstart.init.erb"
        group node['mongodb']['root_group']
        owner "root"
        mode "0755"
        variables({
           :data_dir => dbpath,
           :log_dir => logpath,
           :user => node[:mongodb][:user],
           :group => node[:mongodb][:group],
           :config =>configfile,
           :pidfile => "#{node[:mongodb][:pidpath]}/#{name}.pid"
        })   
    end

    
  end
  
  # init script
  

  
  bash "turn #{name} transparent page enabled and defrag to never" do
        user "root"
        code <<-EOH
          echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
          echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
        EOH
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
            :path => "/vol/log/mongodb",
            :pattern => "#{name}.log",
            :user => node[:mongodb][:user],
            :pid_file => "#{node[:mongodb][:pidpath]}/#{name}.pid"
          )
  end
  


  # replicaset
  if !replicaset_name.nil?
      rs_nodes = nil
      if Chef::Config[:solo]
        rs_nodes = node[:mongodb][:replicaset_members]
      else
        rs_nodes = search(
          :node,
          "mongodb_cluster_name:#{replicaset['mongodb']['cluster_name']} AND \
           recipes:mongodb\\:\\:replicaset AND \
           mongodb_shard_name:#{replicaset['mongodb']['shard_name']} AND \
           chef_environment:#{replicaset.chef_environment}"
        )
      end  


    #ruby_block "config_replicaset" do
      #block do
       # if not replicaset.nil?
        #  MongoDB.configure_replicaset(replicaset, replicaset_name, rs_nodes)
       # end
      #end
      #action :nothing
    #end
  end
  
  # sharding
  if type == "mongos"
    # add all shards
    # configure the sharded collections
    
    shard_nodes = search(
      :node,
      "mongodb_cluster_name:#{node['mongodb']['cluster_name']} AND \
       recipes:mongodb\\:\\:shard AND \
       chef_environment:#{node.chef_environment}"
    )
    
    ruby_block "config_sharding" do
      block do
        if type == "mongos"
          MongoDB.configure_shards(node, shard_nodes)
          MongoDB.configure_sharded_collections(node, node['mongodb']['sharded_collections'])
        end
      end
      action :nothing
    end
  end
end

