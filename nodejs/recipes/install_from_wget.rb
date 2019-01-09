# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


bash "install nodejs" do
  cwd   "/tmp"
  user  "root"
  group "root"
  timeout 7200
  code <<-EOH

      wget http://nodejs.org/dist/v#{node['nodejs']['version']}/node-v#{node['nodejs']['version']}.tar.gz
      tar -xvf node-v#{node['nodejs']['version']}.tar.gz
      cd node-v#{node['nodejs']['version']}
      ./configure
      make 
      make install
  EOH
end  
