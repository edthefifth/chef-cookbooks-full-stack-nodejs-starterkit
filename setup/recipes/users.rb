# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


include_recipe "setup::default"

node[:ssh_users].each do |unixid,user|
  
  bash "add #{user[:name]} to group" do
    user "root"
    code <<-EOH
      usermod -a -G #{node[:setup][:group]} #{user[:name]}
    EOH
  end
  
  #template "/home/#{user[:name]}/.hgrc" do
  #  source "hgrc.erb"
  #  owner user[:name]
  #  group node[:setup][:group]
  #  mode 00644
  #  variables(:name => user[:name],:email => user[:email], :group=>node[:setup][:group])
  #end

  
  
end