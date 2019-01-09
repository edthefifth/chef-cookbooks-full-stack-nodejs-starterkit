# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

cookbook_file "#{node["rsyslog"]["defaults_file"]}" do
  source "rsyslog.default"
  owner node['rsyslog']['user']
  group node['rsyslog']['group']
  mode 0644
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
