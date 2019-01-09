#
# Cookbook Name:: mongodb
# Recipe:: replicatset
#
# Copyright 2011, edelight GmbH
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

include_recipe "mongodb"

node.default[:main][:url] = node[:opsworks][:layers]["db"][:instances]['main-db'][:private_ip] || 'localhost'
node.default[:arbiter][:url] = node[:opsworks][:layers]["db"][:instances]['arbiter-db1'][:private_ip] || 'localhost'
node.default[:backup][:url] = node[:opsworks][:layers]["db"][:instances]['backup-db1'][:private_ip] || 'localhost'

# if we are configuring a shard as a replicaset we do nothing in this recipe
if !node.recipes.include?("mongodb::shard")
  mongodb_instance "mongod" do
    mongodb_type "mongod"
    port         node['main']['port']
    logpath      node['main']['logpath']
    dbpath       node['main']['dbpath']
    replicaset   node['mongodb']['replicaset_name']
    enable_rest  node['mongodb']['enable_rest']
    configfile   node['main']['configfile']
    
  end
  mongodb_instance "mongoa" do
    mongodb_type "mongod"
    port         node['arbiter']['port']
    logpath      node['arbiter']['logpath']
    dbpath       node['arbiter']['dbpath']
    replicaset   node['mongodb']['replicaset_name']
    enable_rest  node['mongodb']['enable_rest']
    configfile   node['arbiter']['configfile']
  end
  mongodb_instance "mongob" do
    mongodb_type "mongod"
    port         node['backup']['port']
    logpath      node['backup']['logpath']
    dbpath       node['backup']['dbpath']
    replicaset   node['mongodb']['replicaset_name']
    enable_rest  node['mongodb']['enable_rest']
    configfile   node['backup']['configfile']
  end
  
  
template "#{node['mongodb']['defaults_dir']}/setup_replset.js" do
    action :create
    source "setup_replset.js.erb"
    owner node[:mongodb][:user]
    group node[:mongodb][:group]
    mode '0755'
    variables({ :mongo_replset => node['mongodb']['replicaset_name'],
                :main_port => node['main']['port'],
                :backup_port => node['backup']['port'],
                :arbiter_port => node['arbiter']['port'],
		:main_url => node['main']['url'],
                :backup_url => node['backup']['url'],
                :arbiter_url => node['arbiter']['url'],
             })
  end


      

#----- wait for set members to be up and initialize -----

 execute "wait for mongo on #{node['backup']['port']} to come up" do
   command "until echo 'exit' | /usr/bin/mongo localhost:#{node['backup']['port']}/local --quiet; do sleep 10s; done"
 end

 execute "wait for mongo on #{node['main']['port']} to come up" do
   command "until echo 'exit' | /usr/bin/mongo localhost:#{node['main']['port']}/local --quiet; do sleep 10s; done"
 end

 execute "wait for mongo on #{node['arbiter']['port']} to come up" do
   command "until echo 'exit' | /usr/bin/mongo localhost:#{node['arbiter']['port']}/local --quiet; do sleep 10s; done"
 end


# ----- configure the repl set
execute "setup replset #{node[:mongodb][:replicaset_name]}" do
  command "/usr/bin/mongo local #{node['mongodb']['defaults_dir']}/setup_replset.js"
  only_if "echo 'rs.status()' | /usr/bin/mongo local --quiet | grep -q 'run rs.initiate'"
  Chef::Log.info "Replica set node initialized"
end

 
     
#make sure mongo repl primary node is set
script "check_repl" do
      interpreter "bash"
      user "root"
      code <<-EOH
        while true
          do output=`mongostat --port=27017 --noheaders -n 1| sed -n 2p`;array=($output)
            test=${array[19]}
            if [ $test = 'PRI' ]
              then
                break
              else
                continue
            fi
            output2=`mongostat --port=27019 --noheaders -n 1| sed -n 2p`
            array2=($output2)
            test2=${array2[19]}
            if [ $test2 = 'PRI' ]
              then
                break
              else
                continue
              fi
          done
      EOH
    end 
end

   












