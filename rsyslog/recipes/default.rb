#
# Cookbook Name:: rsyslog
# Recipe:: default
#
# Copyright 2009-2011, Opscode, Inc.
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

package "rsyslog" do
  action :install
end


directory "/etc/rsyslog.d" do
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0755
end

directory "/var/spool/rsyslog" do
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0755
end


template "/etc/logrotate.d/syslog" do
  source "syslog.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

template "/etc/logrotate.d/yum.log" do
  source "empty_log.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end


include_recipe "rsyslog::nginx"

case node['platform']
when 'debian', 'ubuntu'
  # do debian/ubuntu things
when 'redhat', 'centos', 'fedora'
  # do redhat/centos/fedora things
end

if platform_family?("rhel") && node['platform'] != 'amazon'
  service "#{node['rsyslog']['service_name']}" do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :reload => true
    action [:enable, :start]
  end
else
  service "#{node['rsyslog']['service_name']}" do
    supports :restart => true, :reload => true
    action [:enable, :start]
  end
end
