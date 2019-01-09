#
# Author:: Ed Sullivan
# Cookbook Name:: nodejs
# Recipe:: forever
#

execute "install_forever_module" do
  user "root"
  group "root"
  command "npm install forever"
end
