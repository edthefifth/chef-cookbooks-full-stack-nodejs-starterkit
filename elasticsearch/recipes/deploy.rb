if not node[:opsworks][:instance][:layers].include?("elasticsearch")
      Chef::Log.info("Skipping elasticsearch::install on #{node[:opsworks][:instance][:hostname]} because layer elasticsearch is not installed on this instance")
      return
end

[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

Erubis::Context.send(:include, Extensions::Templates)

 node.normal[:elasticsearch][:custom_config]["network.bind_host"] = "#{node[:opsworks][:instance][:private_ip]}"
 node.normal[:elasticsearch][:custom_config]["network.publish_host"] = "#{node[:opsworks][:instance][:private_ip]}"

include_recipe "ark"
include_recipe "java"

# Create ES directories
#
[ node.elasticsearch[:path][:conf], node.elasticsearch[:path][:logs] ].each do |path|
  directory path do
    owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
    recursive true
    action :create
  end
end

directory node.elasticsearch[:pid_path] do
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode '0755'
  recursive true
end

# Create data path directories
#
data_paths = node.elasticsearch[:path][:data].is_a?(Array) ? node.elasticsearch[:path][:data] : node.elasticsearch[:path][:data].split(',')

data_paths.each do |path|
  directory path.strip do
    owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
    recursive true
    action :create
  end
end

# Create service
#
name = "elasticsearch"

case node[:platform]
  when 'centos','redhat','fedora' 

  
    template "/etc/systemd/system/#{name}.service" do
      source "elasticsearch.systemd.erb"
      owner 'root' and mode 0755
      variables(
        :home_dir => node[:elasticsearch][:path][:home],
        :conf_dir => node[:elasticsearch][:path][:conf],
        :data_dir => node[:elasticsearch][:path][:data],
        :log_dir => node[:elasticsearch][:path][:logs],
        :pid_file => node.elasticsearch[:pid_file],
        :env_file => node.elasticsearch[:path][:conf]+"/elasticsearch-env.sh",
        :auto_restart => true
      )
    end
      template "/etc/init.d/#{name}" do
        source "elasticsearch.init.erb"
        owner 'root' and mode 0755
      end
  
  else

end
service "#{name}" do
  supports :status => true, :restart => true
  action [ :enable ]
end

# Download, extract, symlink the elasticsearch libraries and binaries
#
ark_prefix_root = node.elasticsearch[:dir] || node.ark[:prefix_root]
ark_prefix_home = node.elasticsearch[:dir] || node.ark[:prefix_home]

filename = node.elasticsearch[:filename] || "elasticsearch-#{node.elasticsearch[:version]}.tar.gz"
download_url = node.elasticsearch[:download_url] || [node.elasticsearch[:host],
                node.elasticsearch[:repository], filename].join('/')

ark "elasticsearch" do
  url   download_url
  owner node.elasticsearch[:user]
  group node.elasticsearch[:user]
  version node.elasticsearch[:version]
  has_binaries ['bin/elasticsearch', 'bin/plugin']
  checksum node.elasticsearch[:checksum]
  prefix_root   ark_prefix_root
  prefix_home   ark_prefix_home

  notifies :start,   'service[elasticsearch]' unless node.elasticsearch[:skip_start]
  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]

  not_if do
    link   = "#{node.elasticsearch[:dir]}/elasticsearch"
    target = "#{node.elasticsearch[:dir]}/elasticsearch-#{node.elasticsearch[:version]}"
    binary = "#{target}/bin/elasticsearch"

    ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target && ::File.exists?(binary)
  end
end

# Increase open file and memory limits
#
bash "enable user limits" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  END

  not_if { ::File.read("/etc/pam.d/su").match(/^session    required   pam_limits\.so/) }
end

file "/etc/security/limits.d/10-elasticsearch.conf" do
  content <<-END.gsub(/^    /, '')
    #{node.elasticsearch.fetch(:user, "elasticsearch")}     -    nofile    #{node.elasticsearch[:limits][:nofile]}
    #{node.elasticsearch.fetch(:user, "elasticsearch")}     -    memlock   #{node.elasticsearch[:limits][:memlock]}
  END

  notifies :write, 'log[increase limits]', :immediately
end

log "increase limits" do
  message "increased limits for the elasticsearch user"
  action :nothing
end
#
## Create file with ES environment variables
#
template "elasticsearch-env.sh" do
  path   "#{node.elasticsearch[:path][:conf]}/elasticsearch-env.sh"
  source node.elasticsearch[:templates][:elasticsearch_env]
  owner  node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, "service[#{name}]" unless node.elasticsearch[:skip_restart]
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node.elasticsearch[:path][:conf]}/elasticsearch.yml"
  source node.elasticsearch[:templates][:elasticsearch_yml]
  owner  node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, "service[#{name}]" unless node.elasticsearch[:skip_restart]
end

# Create ES logging file
#
template "logging.yml" do
  path   "#{node.elasticsearch[:path][:conf]}/logging.yml"
  source node.elasticsearch[:templates][:logging_yml]
  owner  node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, "service[#{name}]" unless node.elasticsearch[:skip_restart]
end






