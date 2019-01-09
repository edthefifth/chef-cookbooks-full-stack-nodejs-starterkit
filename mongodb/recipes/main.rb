#
# Cookbook Name:: mongodb
# Recipe:: prod_main
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


case node['platform']
  when "centos","redhat","fedora"
    redhat_mongodb_instance 'mongod' do
      mongodb_type "mongod"
      port         node['main']['port']
      logpath      node['main']['logpath']
      dbpath       node['main']['dbpath']
      configfile   node['main']['configfile']
    end
  else
    mongodb_instance "mongod" do
        mongodb_type "mongod"
        port         node['main']['port']
        logpath      node['main']['logpath']
        dbpath       node['main']['dbpath']
        replicaset   node['mongodb']['replicaset_name']
        enable_rest  node['mongodb']['enable_rest']
        configfile   node['main']['configfile']
    end
end

















