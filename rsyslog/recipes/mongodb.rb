#
# Cookbook Name:: rsyslog
# Recipe:: mongodb
#

template "/etc/logrotate.d/mongodb_log" do
  source "generic_log.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  variables(
          :path => "/vol/log/mongodb",
          :pattern => "*.log",
          :user => node[:mongodb][:user]
        )
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end
