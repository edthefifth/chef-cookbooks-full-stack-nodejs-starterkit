# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

service "#{node['arbiter']['name']}" do
  supports :restart => true, :reload => false, :status => true
  action :nothing
end
