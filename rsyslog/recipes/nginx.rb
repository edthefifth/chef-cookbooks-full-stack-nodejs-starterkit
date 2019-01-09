# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

template "/etc/logrotate.d/nginx" do
  source "nginx_log.erb"
  backup false
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
  variables(
          :path => "/vol/log/docker/nginx",
          :pattern => "*log",
          :user => node['rsyslog']['user']
        )
  notifies :restart, "service[#{node['rsyslog']['service_name']}]"
end
