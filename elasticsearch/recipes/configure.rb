##
#

bash 'create /vol/elasticsearch_indexes.out' do
    user "root"
    code <<-EOH
      echo '{"msg":"setup"}' >> /vol/elasticsearch_indexes.out
      chown root:#{node[:setup][:group]} /vol/elasticsearch_indexes.out
      chmod 664 /vol/elasticsearch_indexes.out
    EOH
    not_if {File.exists?("/vol/conf/document.key")}
end

if not node[:opsworks][:instance][:layers].include?("elasticsearch")
      Chef::Log.info("Skipping elasticsearch::install on #{node[:opsworks][:instance][:hostname]} because layer elasticsearch is not installed on this instance")
      return
end



begin
    run_context.resource_collection.find("service[elasticsearch]")
    false
  rescue Chef::Exceptions::ResourceNotFound
    service "elasticsearch" do
      supports :restart=>true,:status=>true
      action [:enable]
    end
end
  
  execute "sleep for a second to restart elasticsearch" do
      user "root"
      command "sleep 1"
      notifies :restart, "service[elasticsearch]", :immediately
  end
  
  



