# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

define :aws_log_file_entry,:file=>"/etc/s3cfg.conf",:log=>"/var/log/messages", :user=>'root', :group=>"root" do

  file = params[:file]
  log = params[:log]
  group = params[:group]
  user = params[:user]
  
  if log =~ /mongo/
    format = '%Y-%m-%dT%H:%M:%S%z'
  elsif log =~ /access/
    format = '[%d/%b/%Y:%H:%M:%S %z]'
  elsif log =~ /error/
    format = '%Y/%m/%d %H:%M:%S'  
  else  
    format = '[%B %d, %Y, %H:%M ]'
  end  
  
  if File.exists?(log)
    bash "configure awslogs" do
      user "root"
      code <<-EOH
          echo '\n' >> #{file}
          echo '[#{log}]' >> #{file}
          echo 'file = #{log}' >> #{file}
          echo 'log_group_name = #{log}' >> #{file}
          echo 'log_stream_name = {instance_id}' >> #{file}
          echo 'datetime_format = #{format}' >> #{file}
      EOH
      not_if "grep #{log} #{file}"
    end
  end
  
  
  

end
