# Override the cookbook's default attributes in this file.
#
# Usually, you don't change this file directly, but you'll create a "elasticsearch/attributes/customize.rb" file
# in your wrapper cookbook and put the overrides in that file.
#
# The following shows how to override the Elasticsearch version and cluster name settings:
#
# normal[:elasticsearch][:version] = '1.1.0'
# normal[:elasticsearch][:cluster][:name] = 'my-cluster'

normal[:elasticsearch][:version] = '2.4.1'
normal[:elasticsearch][:host]          = "http://download.elasticsearch.org"
normal[:elasticsearch][:repository]    = "elasticsearch/elasticsearch"
normal[:elasticsearch][:filename]      = nil
normal[:elasticsearch][:download_url]  = nil

normal[:elasticsearch][:cluster][:name] = "elasticsearch-#{node[:setup][:env]}"
normal[:elasticsearch][:node][:name]    = "elasticsearch-#{node["opsworks"]["instance"]["hostname"]}"

normal[:elasticsearch][:dir]       = "/usr/local"
normal[:elasticsearch][:bindir]    = "/usr/local/bin"
normal[:elasticsearch][:user]      = "elasticsearch"
normal[:elasticsearch][:uid]       = nil
normal[:elasticsearch][:gid]       = nil

normal[:elasticsearch][:path][:home] = "/usr/local/elasticsearch"
normal[:elasticsearch][:path][:conf] = "/etc/elasticsearch"
normal[:elasticsearch][:path][:data] = "/vol/lib/elasticsearch"
normal[:elasticsearch][:path][:logs] = "/vol/log/elasticsearch"

normal[:elasticsearch][:pid_path]  = "/var/run/elasticsearch"
normal[:elasticsearch][:pid_file]  = "#{node[:elasticsearch][:pid_path]}/#{node[:elasticsearch][:node][:name].to_s.gsub(/\W/, '_')}.pid"

normal[:elasticsearch][:templates][:elasticsearch_env] = "elasticsearch-env.sh.erb"
normal[:elasticsearch][:templates][:elasticsearch_yml] = "elasticsearch.yml.erb"
normal[:elasticsearch][:templates][:logging_yml]       = "logging.yml.erb"

normal[:elasticsearch][:custom_config]["network.bind_host"] = "#{node[:opsworks][:instance][:private_ip]}"
normal[:elasticsearch][:custom_config]["network.publish_host"] = "#{node[:opsworks][:instance][:private_ip]}"

