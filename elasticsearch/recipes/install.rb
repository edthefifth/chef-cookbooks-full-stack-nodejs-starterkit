if not node[:opsworks][:instance][:layers].include?("elasticsearch")
      Chef::Log.info("Skipping elasticsearch::install on #{node[:opsworks][:instance][:hostname]} because layer elasticsearch is not installed on this instance")
      return
end

[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

Erubis::Context.send(:include, Extensions::Templates)

include_recipe "java::default"

Chef::Log.debug(node[:elasticsearch])

elasticsearch = "elasticsearch-#{node[:elasticsearch][:version]}"

include_recipe "elasticsearch::curl"

# Create user and group
#
group node[:elasticsearch][:user] do
  gid node[:elasticsearch][:gid]
  action :create
  system true
end

user node.elasticsearch[:user] do
  comment "ElasticSearch User"
  home    "#{node[:elasticsearch][:dir]}/elasticsearch"
  shell   "/bin/bash"
  uid     node[:elasticsearch][:uid]
  gid     node[:elasticsearch][:user]
  supports :manage_home => false
  action  :create
  system true
end

# FIX: Work around the fact that Chef creates the directory even for `manage_home: false`
bash "remove the elasticsearch user home" do
  user    'root'
  code    "rm -rf  #{node[:elasticsearch][:dir]}/elasticsearch"
  not_if  { ::File.symlink?("#{node[:elasticsearch][:dir]}/elasticsearch") }
  only_if { ::File.directory?("#{node[:elasticsearch][:dir]}/elasticsearch") }
end
