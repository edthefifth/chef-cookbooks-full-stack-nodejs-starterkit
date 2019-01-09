# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

Chef::Log.info("Starting setup::install")

include_recipe "selinux::disabled"

# execute once on each machine so break at the end
node[:deploy].each do |application, deploy|
 
  user = node[:ssh_users]["2002"] || node[:ssh_users]["2001"] || {:name=>"root"}
     
  
  
  #bash "load document root" do
  #  user "root"
  #  group "#{node['setup']['group']}"
  #  cwd "/vol/www"
  #  code <<-EOH
  #    sudo su "#{user[:name]}" -c "hg clone #{deploy[:scm][:repository]} #{node[:setup][:home]} -r #{node[:setup][:branch]}"
  #  EOH
  #  not_if { ::File.directory?(node[:setup][:home]+"/.hg") }
  #end
  
  require 'json'
  
  include_recipe 'git'

  case node[:platform]

    when 'centos','redhat','fedora','amazon'

      execute "run yum update" do
            user "root"
            command "yum clean all && yum update -y"
      end

  end


  #bash "create /vol if doesn't exist" do
  #    user "root"
  #    group "root"
  #    code <<-EOH
  #       ln -s /var /vol
  #    EOH
  #    not_if { ::Dir.exists?("/vol") }
  #end

  
  unixid , user =  node["ssh_users"].first
  
  directory node[:setup][:conf_home] do
        owner     "root"
        group     node[:setup][:group]
        mode      '775'
        recursive true
  end
  
  directory node[:setup][:lib_home] do
        owner     "root"
        group     node[:setup][:group]
        mode      '775'
        recursive true
  end
  
  directory node[:setup][:log_home] do
        owner     "root"
        group     node[:setup][:group]
        mode      '775'
        recursive true
  end


  bash "create group" do
    user "root"
    code <<-EOH
      groupadd #{node[:setup][:group]}
    EOH
    not_if "getent group #{node[:setup][:group]}"
  end
  
  bash "add #{user[:name]} to #{node[:setup][:group]}" do
    user "root"
    code <<-EOH
      usermod -a -G #{node[:setup][:group]} #{user[:name]}
    EOH
  end

  bash "create env home" do
    user "root"
    code <<-EOH
      mkdir -p "#{node[:setup]['home_dir']}"
      chown root:#{node[:setup][:group]} "#{node['setup']['home_dir']}"
      chmod 2775 "#{node['setup']['home_dir']}"
    EOH
  end

  bash "load private_ip address" do
    user "root"
    code <<-EOH
      echo "#{node[:opsworks][:instance][:private_ip]}  localhost" >> /etc/hosts
    EOH
    not_if "grep -r #{node[:opsworks][:instance][:private_ip]} /etc/hosts"
  end
  

  

  break   
end
