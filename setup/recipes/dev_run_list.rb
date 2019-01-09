# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.
puts("node[cpu][total] = #{node['cpu']['total']}") 
## new attribute 
puts("node[nginx][worker_processes] = #{node['nginx']['worker_processes']}")
#setup
include_recipe "setup::install"
include_recipe "mongodb::install"
include_recipe "nginx::install"
include_recipe "nodejs::install"
include_recipe "rsyslog::install"
include_recipe "elasticsearch::install"

#Deploy
include_recipe "setup::deploy"
include_recipe "mongodb::deploy"
include_recipe "nodejs::deploy"
include_recipe "elasticsearch::deploy"
include_recipe "rsyslog::deploy"

#Configure
include_recipe "setup::configure"
include_recipe "mongodb::configure"
include_recipe "rsyslog::configure"
include_recipe "nodejs::configure"
include_recipe "elasticsearch::configure"
include_recipe "nginx::configure"



