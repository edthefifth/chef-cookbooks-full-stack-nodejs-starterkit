# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

service "nginx" do
  supports :restart => true, :reload => true, :status => true
  action :nothing
end
