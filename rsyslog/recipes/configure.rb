# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

template "/etc/rsyslog.conf" do
  source 'rsyslog.conf.erb'
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  variables(:protocol => node['rsyslog']['protocol'])
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

template "/etc/rsyslog.d/50-default.conf" do
  source "50-default.conf.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

template "/etc/logrotate.d/custom_logs" do
  source "custom-logs.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end


template "/etc/logrotate.d/syslog" do
  source "syslog.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

template "/etc/logrotate.d/yum" do
  source "empty_log.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end

include_recipe "rsyslog::nginx"


service "#{node['rsyslog']['service_name']}" do
  supports :restart => true, :reload => true
  action [:enable, :start]
end

