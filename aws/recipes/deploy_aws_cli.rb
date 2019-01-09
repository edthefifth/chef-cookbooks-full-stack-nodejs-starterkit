# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


dir_name =  "/root/.aws"
file_name = "#{dir_name}/config"

access_key=node['deploy']['main_db'][:environment_variables][:aws_key]
secret_key=node['deploy']['main_db'][:environment_variables][:aws_secret]
  
directory "#{dir_name}" do
  owner     "root"
  group     "root"
  mode      0700
  recursive true
  not_if { ::File.exist?(dir_name) }
end

template "#{file_name}" do
        action :create
        cookbook "aws-api"
        source "aws.config.erb"
        owner "root"
        group "root"
        mode "0600"
        variables(
          "access_key"=>access_key,
          "secret_key"=>secret_key
        )
        not_if { ::File.exists?(file_name) }
end