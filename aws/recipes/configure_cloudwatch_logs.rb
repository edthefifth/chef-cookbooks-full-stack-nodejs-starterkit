# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


dir_name =  "/etc/awslogs"
file_name = "#{dir_name}/awslogs.conf"

directory "#{dir_name}" do
  owner     "root"
  group     "root"
  mode      0700
  recursive true
  not_if { ::File.exist?(dir_name) }
end

template "#{file_name}" do
        action :create
        cookbook "aws-api"
        source "awslogs.conf.erb"
        owner "root"
        group "root"
        mode "0600"
        not_if { ::File.exists?(file_name) }
end




node[:aws][:logs].each do |log|
  aws_log_file_entry "new #{log} entry to awslogs.conf" do
    log   log
    file  file_name
  end
end


bash "configure awslogs" do
    user "root"
    cwd  dir_name
    code <<-EOH
      curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
      chmod 744 ./awslogs-agent-setup.py
      ./awslogs-agent-setup.py -n -r #{node[:opsworks][:instance][:region]} -c #{file_name}
    EOH
end

if %w{centos redhat fedora}.include?(node[:platform])
  execute "reload systemctl daemon for awslogs" do
    user "root"
    command "systemctl daemon-reload"
  end
end

node[:aws][:logs].each do |log|
  if log =~ /mongo/
    pattern = '[timestamp, connection, command_type, document, ... , ntoreturn, ntoskip, nscanned, nscannedObjects, keyUpdates, numYields, locks, r, nreturned, reslen = reslen*, response_time]'
    metric_value = '$response_time'
    if log =~ /mongoa/
      metric_preface = "MongoAResponseTime"
    elsif log =~ /mongob/
      metric_preface = "MongoBResponseTime"
    else
      metric_preface = "MongoDResponseTime"
    end
  elsif log =~ /access/
    pattern = '[ip, id, user, timestamp, request, status_code, body_size, http_referrer, http_user_agent, request_time, response_time]'
    metric_value = '$response_time'
    if log =~ /web/
      metric_preface = "WebResponseTime"
    elsif log =~ /api/
      metric_preface = "ApiResponseTime"
    elsif log =~ /admin/
      metric_preface = "AdminResponseTime"
    else
      metric_preface = "GenericServerResponseTime"
    end 
  elsif log =~ /query_stats/
    metric_value = '$.execution_time'
    pattern = '{$.execution_time > 0}'
    metric_preface = "MongoQueryTime"  
  else  
    pattern = nil
  end
  
  
  environ = node[:env_setup][:env].upcase
  if !pattern.nil?
      bash "configure awslogs response time metric" do
        user "root"
        code <<-EOH
            aws logs put-metric-filter --region '#{node[:opsworks][:instance][:region]}' --log-group-name '#{log}' --filter-name '#{metric_preface}' --filter-pattern '#{pattern}' --metric-transformations 'metricName=#{metric_preface},metricNamespace=LogMetrics/Environment/#{environ}/#{node["opsworks"]["instance"]["hostname"]},metricValue=#{metric_value}'
        EOH
      end
  end
end

 

     
  
