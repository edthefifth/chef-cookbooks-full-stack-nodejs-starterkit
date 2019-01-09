#Setup s3cmd

  if node[:deploy].key?("main_db")
    
      
    db_server_name,db_server = node[:opsworks][:layers]["main-db"][:instances].first || node[:opsworks][:instance];
    main_host = db_server[:private_ip]
    deploy = node[:deploy][:main_db]

    if deploy[:environment_variables].key?('aws_key')

      configure "s3cmd" do
        user          node[:aws][:user]
        group         node[:aws][:group]
        config_file   node[:aws][:config]
        access_key    deploy[:environment_variables][:aws_key]
        secret_key    deploy[:environment_variables][:aws_secret]
      end
    
    end
    
  
  end

 
