define :config_lang,  :user=>'root' , :group=>"root", :log=>'/vol/log/php.log', :type=>'npm',:docker_home=>"/container", :home=>"/vol", \
  :host=>"127.0.0.1",:port=>"44444", :rsyslog_conf=>nil do
  name = params[:name]
  user = params[:user]
  group = params[:group]
  log= params[:log]
  type = params[:type]
  home = params[:home] 
  docker_home = params[:docker_home]
  host = params[:host]
  port = params[:port]
  rsyslog_conf = params[:rsyslog_conf]
  
  
  
  case type
    when "php" 
      directory "#{home}/php" do
        owner     user
        group     group
        mode      '775'
        recursive true
        not_if { ::File.directory?("#{home}/php") }
      end
      
      template "#{home}/php/php-fpm.conf" do
        source "php-fpm.conf.erb"
        cookbook "php"
        owner user
        group group
        mode 00664
        variables(:log =>log,:conf_dir => docker_home+"/php" )
      end
      template "#{home}/php/www.conf" do
        source "www.conf.erb"
        cookbook "php"
        owner user
        group group
        mode 00664
        variables(:user=>user,:group=>group,:host =>host,:port => port )
      end
      
      mem_layer_name,memcached = node[:opsworks][:layers]["memcached-layer"][:instances].first
    
      template "#{home}/php/php.ini" do
        source "fpm.php.ini.erb"
        cookbook "php"
        owner user
        group group
        mode 00664
        variables(:host =>memcached[:private_ip] )
      end
      
      
    
    
    else
      #Do Nothing
  end  
  
  
  
   
end
