#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2010-2012, Promet Solutions
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




case node['platform_family']
  when "debian","ubuntu"
   execute "install npm yum dependecies" do
    user "root"
    command "apt-get install -y gcc g++"
  end
  else 
  execute "install npm yum dependecies" do
    user "root"
    command "yum install -y gcc-c++"
  end
end

include_recipe "nodejs::install_from_#{node['nodejs']['install_method']}"

execute "global npm install" do
    user "root"
    cwd "/root"
    command "npm install n -g && n #{node['nodejs']['version']}"
end


execute "global create node and npm symlinks" do
    user "root"
    cwd "/root"
    command "ln -sf /usr/local/n/versions/node/#{node['nodejs']['version']}/bin/node /usr/bin/node && ln -sf /usr/local/n/versions/node/#{node['nodejs']['version']}/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm"
end






 



