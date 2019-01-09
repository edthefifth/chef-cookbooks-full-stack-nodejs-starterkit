# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

node[:deploy].each do |application, deploy|
  
  if not deploy[:environment_variables].has_key?('nodejs')
    Chef::Log.info("Skipping nodejs::update for #{application}")
    next
  end 
  
  lib_dir = "#{deploy[:environment_variables][:dir]}/#{deploy[:document_root]}"
  
  
  user = node[:ssh_users]["2002"] || node[:ssh_users]["2001"] || {:name=>"root"}

  

  bash "install code base for #{application}" do
    user "root"
    group "#{node['setup']['group']}"
    cwd deploy[:environment_variables][:dir]
    code <<-EOH
      sudo su "#{user[:name]}" -c "git clone #{deploy[:scm][:repository]} #{deploy[:document_root]}"
    EOH
    not_if {  ::Dir.exists?("#{deploy[:environment_variables][:dir]}/#{deploy[:document_root]}/.git") }
    only_if { deploy[:scm].has_key?('repository') }
  end

end  
