# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

file_path = "/vol/aws-mon.sh"

package "bc" do
  action :install
end

cookbook_file "#{file_path}" do
  action :create
  mode 00700
  owner "root"
  group "root"
end

cron "trigger_polling" do
  minute '*'
  hour '*'
  day '*'
  month '*'
  weekday '*'
  action :create
  user "root"
  mailto node['user_setup']['cron_email']
  command "/bin/bash #{file_path} --all-items --bulk-post"
end
