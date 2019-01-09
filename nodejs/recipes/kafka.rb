#
# Author:: Ed Sullivan
# Cookbook Name:: nodejs
# Recipe:: kafka
#
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

execute "install_git" do
  user "root"
  group "root"
  command "yum install -y git"
end

execute "install_kafka_module" do
  user "root"
  group "root"
  command "npm install git+https://github.com/SOHU-Co/kafka-node.git -g"
  not_if "#{node['nodejs']['dir']}/bin/npm -v 2>&1 | grep '#{node['nodejs']['npm']}'"
end

