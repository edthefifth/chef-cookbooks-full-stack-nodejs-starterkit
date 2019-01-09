#
# Author:: Ed Sullivan
# Cookbook Name:: setup
# Recipe:: default
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

require 'json'

case node[:platform]

  when 'centos','redhat','fedora','amazon'

    execute "run yum update" do
          user "root"
          command "yum clean all && yum update -y"
    end

end


#bash "create /vol if doesn't exist" do
#    user "root"
#    group "root"
#    code <<-EOH
#       ln -s /var /vol
#    EOH
#    not_if { ::Dir.exists?("/vol") }
#end

bash "create directories" do
  user "root"
  group "root"
  code <<-EOH
    mkdir -p /vol/lib
    mkdir -p /vol/log
    mkdir -p /vol/conf
  EOH
end


bash "create group" do
  user "root"
  code <<-EOH
    groupadd #{node[:setup][:group]}
  EOH
  not_if "getent group #{node[:setup][:group]}"
end

bash "create env home" do
  user "root"
  code <<-EOH
    mkdir -p "#{node['setup']['home_dir']}"
    chown root:#{node[:setup][:group]} "#{node['setup']['home_dir']}"
    chmod 2775 "#{node['setup']['home_dir']}"
  EOH
end

bash "load private_ip address" do
  user "root"
  code <<-EOH
    echo "#{node[:opsworks][:instance][:private_ip]}  localhost" >> /etc/hosts
  EOH
  not_if "grep -r #{node[:opsworks][:instance][:private_ip]} /etc/hosts"
end











