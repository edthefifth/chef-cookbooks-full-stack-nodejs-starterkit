#
# Author:: Ed Sullivan
# Cookbook Name:: nodejs
# Recipe:: pm2
#

execute "install_pm2_module" do
  user "root"
  group "root"
  command "npm install pm2 -g"
end
