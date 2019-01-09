
require 'json'

define :configure,:config_file=>"/etc/s3cfg.conf",:user=>"root", :group=>"root", \
  :secret_key=>"" ,:access_key=>""  do

  config_file = params[:config_file]
  group = params[:group]
  user = params[:user]
  access_key = params[:access_key]
  secret_key = params[:secret_key]
  
  template "#{config_file}" do
        action :create
        cookbook "aws-api"
        source "s3cfg.erb"
        group group
        owner user
        mode "0640"
        variables(
          "access_key"=>access_key,
          "secret_key"=>secret_key
        )
        not_if {File.exists?("#{config_file}")}
  end


  execute "configure s3cmd" do
      user user
      command "s3cmd --config=#{config_file} ls"
  end
  

end
