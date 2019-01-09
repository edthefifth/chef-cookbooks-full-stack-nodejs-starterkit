# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


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



    node.default[:mongodb][:databases] = node[:mongodb][:databases] || node[:env_setup][:apps].keys
    node.default[:mongodb][:bucket] = node[:mongodb].has_key?(:bucket) ? node[:mongodb][:bucket]  : "#{node[:opsworks][:stack][:name]}/mongodb/backups/#{node[:setup][:env]}"


    node.default[:s3][:config] = node[:s3].has_key?(:config) ? node[:s3][:config] : "/etc/s3cfg.conf";




    db_server_name,db_server = node[:opsworks][:layers]["main-db"][:instances].first || node[:opsworks][:instance];
    node.default[:main][:url] = db_server[:private_ip]


    if node[:main][:port].nil?
      node.default[:main][:port] = 27017
    end




    user = node[:ssh_users]["2002"] || node[:ssh_users]["2001"] || {:name=>"root"}

    node[:mongodb][:databases].each do |file_prefix|

     
      backup_file = "#{file_prefix}-s3backup.sh"

      backup_db_script backup_file do
        user          node[:aws][:user]
        group         node[:aws][:group]
        config_file   node[:aws][:config]
        access_key    deploy[:environment_variables][:aws_key]
        secret_key    deploy[:environment_variables][:aws_secret]
        bucket        node[:mongo][:bucket]
        db_host       node['main']['url']
        db_port       node['main']['port']
        db            file_prefix
      end

      if node[:env_setup][:env] == 'prod' || node[:env_setup][:env] == 'production' || node[:repo_service][:force_backup]
        minute = rand(0..12) * 5
        hour = rand(21..23)
        day =  node[:repo_service][:day_cron]
        executable = "/vol/#{backup_file}"
        cron "set #{executable} cron" do
            minute  "#{minute}"
            hour    "#{hour}"
            weekday "#{day}"
            day     '*'
            month   '*'
            user    "root"
            command "#{executable}"
            only_if {File.exists?(executable)}
        end
      end

    end


  end  

end
 
