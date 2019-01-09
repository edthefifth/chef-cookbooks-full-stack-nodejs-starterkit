

define :install_env_file,  :user=>'root' , :group=>"root", :file=>nil,  :type=>'npm' do
  name = params[:name]
  user = params[:user]
  group = params[:group]
  type = params[:type]
   
  file = node[:setup][:env_file]
  
  web_host = nil
  
  if node[:deploy].key?("web_app")
  
    alt_application = node[:deploy].key?("old_web") ? "old_web" : ( node[:deploy].key?("web") ? "web" : false)

    if alt_application != false  &&  node[:opsworks][:instance][:layers].include?(node[:deploy]["#{alt_application}"][:environment_variables][:layer])
      web_lb=node[:opsworks][:layers].key?("web-lb") ? node[:opsworks][:layers]["web-lb"]["elb-load-balancers"].first : ( node[:opsworks][:layers]["old-web"].key?("elb-load-balancers") ? node[:opsworks][:layers]["old-web"]["elb-load-balancers"].first: {:dns_name=>'localhost'});
      web_host=node[:deploy]["#{alt_application}"][:domains].first
    else
      web_lb=node[:opsworks][:layers].key?("web-lb") ? node[:opsworks][:layers]["web-lb"]["elb-load-balancers"].first : ( node[:opsworks][:layers]["web-app"].key?("elb-load-balancers") ? node[:opsworks][:layers]["web-app"]["elb-load-balancers"].first: {:dns_name=>'localhost'});
      web_host=node[:deploy][:web_app][:domains].first
    end


    web_port = 443
    protocol='https'
    if node[:setup][:env] == 'dev'
      web_port=node[:deploy][:web_app][:environment_variables][:serviceport]
      protocol='http'
    end

    node.default[:setup][:definitions][:addresses][:web_server][:external] = web_host || "localhost"
    node.default[:setup][:definitions][:addresses][:web_server][:internal] = web_lb[:dns_name] || "localhost"
    node.default[:setup][:definitions][:ports][:web_server] = web_port
  end
  
  api_host = nil
  
  if node[:deploy].key?("api_app")
  
    api_lb=node[:opsworks][:layers].key?("api-lb") ? node[:opsworks][:layers]["api-lb"]["elb-load-balancers"].first : ( node[:opsworks][:layers]["api-app"].key?("elb-load-balancers") ? node[:opsworks][:layers]["api-app"]["elb-load-balancers"].first: nil);
    api_host=node[:deploy][:api_app][:domains].first

    api_host=node[:deploy][:api_app][:domains].first
    api_port = 443
    if node[:setup][:env] == 'dev'
      api_port=node[:deploy][:api_app][:environment_variables][:serviceport]
      protocol='http'
    end


    node.default[:setup][:definitions][:addresses][:api_server][:external] = api_host || "localhost"
    node.default[:setup][:definitions][:addresses][:api_server][:internal] = api_lb[:dns_name] || "localhost"
    node.default[:setup][:definitions][:ports][:api_server] = api_port
  end
  
  admin_host = nil
  
  if node[:deploy].key?("adminui_app")
  
    admin_lb=node[:opsworks][:layers].key?("adminui-lb") ? node[:opsworks][:layers]["adminui-lb"]["elb-load-balancers"].first : node[:opsworks][:layers]["adminui-app"]["elb-load-balancers"].first;


    admin_host=node[:deploy][:adminui_app][:domains].first
    admin_port = 443
    if  node[:setup][:env] == 'dev'
      admin_port=node[:deploy][:adminui_app][:environment_variables][:serviceport]
      protocol='http'
    end


    node.default[:setup][:definitions][:addresses][:admin_server][:external] = admin_host || "localhost"
    node.default[:setup][:definitions][:addresses][:admin_server][:internal] = admin_lb[:dns_name] || "localhost"
    node.default[:setup][:definitions][:ports][:admin_server] = admin_port
  end
  
  connection = ''
  connection_iter=0;
  
  node[:opsworks][:layers]["main-db"][:instances].each do |db_server_name,db_server|
    if connection_iter == 0
      connection+="#{db_server[:private_ip]}:#{node[:main][:port]}"
    else
      connection+=",#{db_server[:private_ip]}:#{node[:main][:port]}"
    end
    connection_iter+=1
  end
  
  node[:opsworks][:layers]["backup-db"][:instances].each do |db_server_name,db_server|
    if connection_iter == 0
      connection+="#{db_server[:private_ip]}:#{node[:backup][:port]}"
    else
      connection+=",#{db_server[:private_ip]}:#{node[:backup][:port]}"
    end
    connection_iter+=1
  end
  
  
  
  
  

  db_server_name,db_server = node[:opsworks][:layers]["main-db"][:instances].first || node[:opsworks][:instance];
  node.default[:setup][:definitions][:db] ||= Hash.new;
  node.default[:setup][:definitions][:db][:host] = db_server[:private_ip]
  node.default[:setup][:definitions][:db][:port] =  node[:main][:port]
  node.default[:setup][:definitions][:db][:connection] =  connection
  
  definitions = nil
  
  case type
    when "npm","nodejs"
      
      apps = Hash.new
  

      node[:setup][:apps].each do |web_name,web_app|
        apps[web_name]={
          :site=>web_app[:domain],
          :appID=>web_app[:facebook_app_id]
        }
      end

      node.default[:setup][:definitions][:apps]=apps
    
      definitions = node[:setup][:definitions]
    else
      elasticsearch_array = []
      
      if node[:opsworks][:layers].key?("elasticsearch")
        node[:opsworks][:layers]['elasticsearch'][:instances].each do |e_name,e_server|
          elasticsearch_array << "#{e_server[:private_ip]}:#{node[:elasticsearch][:http][:port]}"
        end
      end
      
      valid_sites = []
      
      node[:deploy].each do |application, deploy|
        
        if(application != 'web' && application != 'old_web' && application != 'web_app' && application != 'adminui_app' && application != 'api_app')
            next
        end
      
        _port = deploy[:environment_variables][:serviceport]  
            
        deploy[:domains].each do |domain|
           
          if node[:setup][:env] == 'dev'
            valid_sites << "#{domain}:#{_port}"
            valid_sites << domain
          elsif domain =~ /\.com$/
            valid_sites << domain 
          else
            Chef::Log.info("Skipping #{domain} as valid_site")
            next
          end  
        end
        valid_sites = valid_sites.uniq
      end
    
      definitions = Hash.new
      definitions[:protocol] = "#{protocol}"
      
      definitions[:env] = node[:setup][:env]
      
      definitions[:valid_sites] = valid_sites
      
      
      
  end  
  
  template file do
      source "env.json.erb"
      cookbook "setup"
      owner user
      group group
      mode 00664
      variables(:definitions => definitions)
  end
  
  
  
   
end
