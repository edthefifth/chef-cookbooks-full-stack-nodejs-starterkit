# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

mongo_password = node[:deploy][:main_db][:environment_variables][:password_value]

node[:opsworks][:instance][:layers].each do |layer|
    
  if layer != "main-db"
      Chef::Log.info("Skipping repo-service::backup for layer #{layer}")
      next
  end

  node[:deploy].each do |application, deploy|

    if(application != 'main_db' && application != 'repo_app')
      Chef::Log.info("Skipping repo service backup enablement for #{application}")
      next
    end

    if !deploy[:environment_variables].key?('aws_key')
      Chef::Log.info("Skipping repo service backup enablement for #{application} because aws is not connected")
      next
    end




    #node.default[:repo_service][:databases] = [node[:opsworks][:stack][:name],"api_sessions","oauth","sessions"]

    node.default[:mongodb][:databases] = node[:mongodb][:databases] || node[:env_setup][:apps].keys
    node.default[:mongodb][:bucket] = node[:mongodb].has_key?(:bucket) ? node[:mongodb][:bucket]  : "#{node[:opsworks][:stack][:name]}/mongodb/backups/#{node[:setup][:env]}"


    node.default[:s3][:config] = node[:s3].has_key?(:config) ? node[:s3][:config] : "/etc/s3cfg.conf";

    

    db_server_name,db_server = node[:opsworks][:layers]["main-db"][:instances].first || node[:opsworks][:instance];
    node.default[:main][:url] = db_server[:private_ip]


    if node[:main][:port].nil?
      node.default[:main][:port] = 27017
    end




     user = node[:ssh_users]["2002"] || node[:ssh_users]["2001"] || {:name=>"root"}


    include_recipe "s3cmd::install_s3tools"

    directory "/vol/s3/backup" do
        owner node[:mongodb][:user]
        group node[:mongodb][:group]
        mode "755"
        recursive true
        action :create
    end


    node[:mongodb][:databases].each do |file_prefix|

      bash "load_s3_#{file_prefix}_tar_files" do
        user "root"
        cwd "/vol/s3"
        code <<-EOH
            LIST=`s3cmd --config="#{node[:s3][:config]}" ls s3://#{node[:mongodb][:bucket]}/#{file_prefix} | awk '{print $4}' | sort -t'-' -k3 -r`
            echo "s3cmd --config='#{node[:s3][:config]}' ls s3://#{node[:mongodb][:bucket]}/#{file_prefix} | awk '{print $4}' | sort -t'-' -k3 -r" > /vol/s3-config.out
            for file in $LIST
            do
                    s3cmd --config="#{node[:s3][:config]}" get "$file" "/vol/s3/#{file_prefix}-s3.tar.gz"               
                    cd /vol/s3
                    tar -xzf #{file_prefix}-s3.tar.gz -C /vol/s3/backup
                    break
            done

            sleep 60
        EOH
        not_if { ::File.exist?("/vol/lib/mongodb/#{file_prefix}.0") }
      end

      bash "mongorestore #{file_prefix}" do
        user "root"
        group "root"
        cwd "/var"
        timeout 10800
        code <<-EOH
          list=`ls -d /vol/s3/backup/dumps/#{file_prefix}* || false`

          if [ ! $list ];then
            list=`ls -d /vol/s3/backup/#{file_prefix}*`
          fi

          for i in $list
          do
            echo "#{node[:main][:url]}:#{node[:main][:port]} $i" >> /vol/s3/mongorestore.out
            mongorestore --host #{node[:main][:url]}:#{node[:main][:port]} -u '#{node[:mongodb][:admin_user]}' -p '#{mongo_password}' --authenticationDatabase=admin  --noIndexRestore "$i" >> /vol/s3-mongorestore.out 2>&1
            break;
          done
          echo "#{file_prefix}" >> /vol/s3-mongorestore.status
        EOH
        not_if { ::File.exist?("/vol/lib/mongodb/#{file_prefix}.0") }
        Chef::Log.info "Mongorestore #{file_prefix}"
      end


    end
    
    bash "clean restore files" do
        user "root"
        group "root"
        cwd "/vol"
        timeout 10800
        code <<-EOH
          rm -r /vol/s3/*
          echo "Remove Success!!" >> /vol/s3-mongorestore.status
        EOH
        only_if { ::Dir.exist?("/vol/s3/backup") }
    end


  end  

end
 
