
define :build_api_ajax,  :user=>'root' , :group=>"root", :dir=>nil, :path=>'', :type=>'npm', \
:protocol=>"https", :api_host=>"", :api_port=>"", :url_path=>"api", :html=>true do
  name = params[:name]
  user = params[:user]
  group = params[:group]
  dir = params[:dir]
  path = params[:path]
  type = params[:type]
  protocol = params[:protocol]
  api_host = params[:api_host]
  api_port = params[:api_port]
  url_path = params[:url_path]
  html = params[:html]
   
  
  case type
    when "npm","nodejs"
      template "#{dir}/#{path}/#{name}.js" do
        source    "ajax.js.erb"
        cookbook  "nodejs"
        owner     user
        group     group
        mode      00644
        variables(:api_url => "#{protocol}://#{api_host}:#{api_port}/#{url_path}/",:html=>html)
      end
    else
      #Do Nothing
  end  
  
  
  
   
end