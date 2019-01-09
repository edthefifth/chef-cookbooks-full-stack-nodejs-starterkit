# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

node[:deploy].each do |application, deploy|
  
  if not deploy[:environment_variables].has_key?('nodejs')
    Chef::Log.info("Skipping nodejs::update for #{application}")
    next
  end 
  
  lib_dir = "#{deploy[:environment_variables][:dir]}/#{deploy[:document_root]}"
  
  
  unixid , user =  node["ssh_users"].first

  

  #bash "update code base" do
  #  user "root"
  #  group "#{node['setup']['group']}"
  #  cwd lib_dir
  #  code <<-EOH
  #    sudo su "#{user[:name]}" -c "git pull origin #{node[:setup][:branch_name]}"
  #  EOH
  #  only_if {  ::Dir.exists?("#{lib_dir}/.git") }
  #end

end  
