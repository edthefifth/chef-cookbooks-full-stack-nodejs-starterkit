

require 'json'

define :backup_db_script,:config_file=>"/etc/s3cfg",:user=>"root", :group=>"root", \
  :bucket=>nil, :db_host=>nil,:db_port=>nil,:db=>nil do
  name = params[:name]
  config_file = params[:config_file]
  group = params[:group]
  user = params[:user]
  bucket = params[:bucket]
  db_host = params[:db_host]
  db_port = params[:db_port]
  db = params[:db]
  

  execute "install jq" do
      user "root"
      command "yum install -y jq"
  end

  include_recipe "aws-api::install_aws_cli"
  include_recipe "aws-api::deploy_aws_cli"
  
  if File.exist?(node[:mongodb][:passwordfile])
    template "/vol/#{name}" do
        action :create
        cookbook "aws-api"
        source "s3backup.password.sh.erb"
        group group
        owner user
        mode "0770"
        variables(
          "bucket"=>bucket,
          "conf"=>config_file,
          "host"=>db_host,
          "port"=>db_port,
          "db"=>db,
          "passwordfile"=>node[:mongodb][:passwordfile]
        )
      end
    else
  
      template "/vol/#{name}" do
            action :create
            cookbook "aws-api"
            source "s3backup.sh.erb"
            group group
            owner user
            mode "0770"
            variables(
              "bucket"=>bucket,
              "conf"=>config_file,
              "host"=>db_host,
              "port"=>db_port,
              "db"=>db
            )
      end
    end  
  
  

end
