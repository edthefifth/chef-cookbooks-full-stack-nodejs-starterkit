
define :install_dependencies,  :user=>'root' , :group=>"root", :dir=>nil, :type=>'npm', :home=>"/vol" do
  name = params[:name]
  user = params[:user]
  group = params[:group]
  code_dir= params[:dir]
  type = params[:type]
  home = params[:home] 
  
  case type
    when "npm","nodejs"
      
      include_recipe "nodejs::npm"
    
      bash "install_dependencies for #{name}" do
        user user
        group group
        cwd code_dir
        code <<-EOH 
          npm install -d
          npm update
        EOH
      end
    else
      #Do Nothing
  end  
  
  
  
   
end

