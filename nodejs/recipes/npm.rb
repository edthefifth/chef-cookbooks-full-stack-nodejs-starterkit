#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: nodejs
# Recipe:: npm
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

package "npm"

#npm_src_url = "http://registry.npmjs.org/npm/-/npm-#{node['nodejs']['npm']}.tgz"

bash "update npm - package manager for node" do
  cwd   "/usr/local/src"
  user  "root"
  group "root"
  code <<-EOH
    npm update npm@#{node['nodejs']['npm']} -g
  EOH
end



