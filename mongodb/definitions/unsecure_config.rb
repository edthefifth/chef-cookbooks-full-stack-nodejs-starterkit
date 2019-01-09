# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

define :unsecure_mongo_config, :main_url => nil,  :current_url => nil, :files_dir => "/vol", :user=>'root', :group => 'root', :nodes=>[] do

    name = params[:name]
    main_url = params[:main_url]
    current_url = params[:current_url]
    files_dir = params[:files_dir]
    user = params[:user]
    group = params[:group]
    rnodes = params[:nodes]
    
    template "#{files_dir}/reconfigure.js" do
      action :create
      source "reconfigure.erb"
      owner  user
      group  group
      mode '0755'
      variables( :host => main_url, :priority => 100)
    end

    execute "reconfig replicaset" do
      command "/usr/bin/mongo --host #{current_url} #{files_dir}/reconfigure.js"
      ignore_failure  true
      only_if {"mongostat --host=#{current_url} --noheaders -n 1 | grep 'PRI'"}
    end
    
    rnodes.each do |node_url|

          if node_url.end_with?(':27017')
            priority = 100
          else
            priority = 1
          end

          execute "add to replset #{current_url} via main #{main_url}" do
            user "root"
            command lazy "/usr/bin/mongo --host #{main_url}  --eval 'printjson(rs.add({\"host\":\"#{node_url}\",\"priority\":#{priority}}))' >> /vol/add_repl.out" 
            not_if "/usr/bin/mongo ---host #{main_url} --eval \"printjson(rs.conf())\" | grep '#{node_url}'"
            not_if {current_url == node_url}
            Chef::Log.info "Adding #{node_url} to replicaset with priority:#{priority}"
          end
    end  
  
end
