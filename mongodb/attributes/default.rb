#
# Cookbook Name:: mongodb
# Attributes:: default
#
# Copyright 2010, edelight GmbH
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
default[:main][:name] = "mongod"
default[:main][:dbpath] = "/vol/lib/mongod"
default[:main][:logpath] = "/vol/log/mongodb"
default[:main][:url] = node['hostname']
default[:main][:port] = 27017
default[:main][:configfile] = "/etc/mongod.conf"

default[:arbiter][:name] = "mongoa"
default[:arbiter][:dbpath] = "/vol/lib/mongoa"
default[:arbiter][:logpath] = "/vol/log/mongodb"
default[:arbiter][:url] = node['hostname']
default[:arbiter][:port] = 27018
default[:arbiter][:configfile] = "/etc/mongoa.conf"


default[:backup][:name] = "mongob"
default[:backup][:dbpath] = "/vol/lib/mongob"
default[:backup][:logpath] = "/vol/log/mongodb"
default[:backup][:url] = node['hostname']
default[:backup][:port] = 27019
default[:backup][:configfile] = "/etc/mongob.conf"


# cluster identifier
default[:mongodb][:databases] = []
default[:mongodb][:admin_user] = 'adminit'
default[:mongodb][:security_on] = true
default[:mongodb][:pidpath] = "/var/run/mongodb"
default[:mongodb][:client_roles] = []
default[:mongodb][:cluster_name] = nil
if node['env_name'] == 'prod'
	default[:mongodb][:replicaset_name] = "main"
else
	default[:mongodb][:replicaset_name] = "dev"
end

default[:mongodb][:shard_name] = "default"

default[:mongodb][:enable_rest] = false

default[:mongodb][:root_group] = "root"

default[:mongodb][:init_dir] = "/etc/systemd/system"

default[:mongodb][:upstart_dir] = "/etc/init"

default[:mongodb][:init_script_template] = "mongodb.init.erb"

default[:mongodb][:defaults_dir] = "/etc/sysconfig"


default[:mongodb][:s3_path]= "mongo-backups/#{node['env_name']}"



default[:mongodb][:keyfile]='/vol/conf/mongo.key'
default[:mongodb][:passwordfile]='/vol/conf/mongo.p'
default[:mongodb][:keyfile_text]='#keyFile='
default[:mongodb][:password] = SecureRandom.hex(16)
default[:mongodb][:key_val] = SecureRandom.base64(768) # 768 bytes = 1024 character key file

default[:mongodb][:version] = '3.4'
default[:mongodb][:user] = "mongod"
default[:mongodb][:group] = "mongod"




case node['platform']
when "freebsd"
  default[:mongodb][:defaults_dir] = "/etc/rc.conf.d"
  default[:mongodb][:init_dir] = "/usr/local/etc/rc.d"
  default[:mongodb][:root_group] = "wheel"
  default[:mongodb][:package_name] = "mongodb"

when "centos","redhat","fedora",
    default[:mongodb][:init_dir] = "/etc/systemd/system"
    default[:mongodb][:defaults_dir] = "/etc/sysconfig"
    default[:mongodb][:package_name] = "mongodb-org"
    default[:mongodb][:init_script_template] = "mongod.service.erb"
when "amazon"
  default[:mongodb][:defaults_dir] = "/etc/sysconfig"
  default[:mongodb][:package_name] = "mongodb-org"
  default[:mongodb][:init_script_template] = "mongod.init.erb"
else
  default[:mongodb][:defaults_dir] = "/etc/default"
  default[:mongodb][:root_group] = "root"
  default[:mongodb][:package_name] = "mongodb-org"
  default[:mongodb][:user] = "mongodb"
  default[:mongodb][:group] = "mongodb"
end
