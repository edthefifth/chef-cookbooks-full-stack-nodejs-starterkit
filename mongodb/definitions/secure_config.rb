# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.



define :secure_mongo_config, :main_url => nil,  :current_url => nil, :files_dir => "/vol", :user=>'root', :group => 'root', \
:username => nil, :password => nil, :nodes=>[] do

    name = params[:name]
    main_url = params[:main_url]
    current_url = params[:current_url]
    username = params[:username] || node[:mongodb][:admin_user]
    password = params[:password]
    files_dir = params[:files_dir]
    user = params[:user]
    group = params[:group]
    rnodes = params[:nodes]
    
  Chef::Log.info("Secure Configuring for #{current_url} with #{main_url}")
  Chef::Log.debug(rnodes)
  
          if main_url.end_with?(':27017')
            _priority = 100
          else
            _priority = 1
          end
    
          template "#{files_dir}/reconfigure.js" do
            action :create
            source "reconfigure.erb"
            owner user
            group group
            mode '0755'
            variables( :host => main_url, :priority => _priority)
            only_if "mongostat --host=#{main_url} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --noheaders -n 1 | grep 'PRI'"
            not_if {current_url == main_url}
            not_if {::File.exist?("#{files_dir}/reconfigure.js")}
          end

          execute "#{name} reconfig replicaset" do
            command "/usr/bin/mongo --host #{current_url} -u #{username} -p '#{password}' --authenticationDatabase=admin #{files_dir}/reconfigure.js"
            ignore_failure  true
            only_if "mongostat --host=#{current_url} -u #{username} -p '#{password}' --authenticationDatabase=admin --noheaders -n 1 | grep 'PRI'"
            not_if {current_url == main_url}
          end
    
    
    
          rnodes.each do |node_url|

              Chef::Log.info "Trying to add #{node_url} to replicaset with main server:#{main_url}"
              if node_url.end_with?(':27017')
                priority = 100
              else
                priority = 1
              end

              execute "#{name} test pre repl #{node_url} via main #{main_url}" do
                user "root"
                command "mongostat --host=#{main_url} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --noheaders -n 1 | grep 'PRI' >> /vol/repl_test" 
                ignore_failure true
                Chef::Log.info "Adding #{node_url} to replicaset with priority:#{priority}"
              end

              execute "#{name} rs find pre repl #{node_url} via main #{main_url}" do
                user "root"
                command "/usr/bin/mongo --host #{main_url} -u #{username} -p '#{password}' --authenticationDatabase=admin --eval \"printjson(rs.conf())\" | grep '#{node_url}' >> /vol/repl_test" 
                ignore_failure true
                Chef::Log.info "Adding #{node_url} to replicaset with priority:#{priority}"
              end

              execute "#{name} add to replset #{node_url} via main #{main_url}" do
                user "root"
                command "/usr/bin/mongo --host #{main_url} -u #{username} -p '#{password}' --authenticationDatabase=admin --eval 'printjson(rs.add({\"host\":\"#{node_url}\",\"priority\":#{priority}}))' >> /vol/add_repl.out" 
                only_if "mongostat --host=#{main_url} -u '#{node[:mongodb][:admin_user]}' -p '#{password}' --authenticationDatabase=admin --noheaders -n 1 | grep 'PRI'"
                not_if "/usr/bin/mongo --host #{main_url} -u #{username} -p '#{password}' --authenticationDatabase=admin --eval \"printjson(rs.conf())\" | grep '#{node_url}'"
                Chef::Log.info "Adding #{node_url} to replicaset with priority:#{priority}"
              end
          end
       
        

  
end
