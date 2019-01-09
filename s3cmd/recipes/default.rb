#Install s3cmd


package "s3cmd" do
    action :install
end



#Setup s3cmd
aws_creds = Chef::EncryptedDataBagItem.load("passwords", "aws")

template "#{node[:s3][:config]}" do
      action :create
      source "s3cmd.conf.erb"
      group "root"
      owner "root"
      mode "0640"
      variables(
        "access_key"=>aws_creds['access'],
        "secret_key"=>aws_creds['secret']
      )
end


execute "configure s3cmd" do
    command "s3cmd --config=#{node[:s3][:config]} ls"
end

