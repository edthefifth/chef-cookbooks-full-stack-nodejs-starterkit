# nodejs::update

node[:deploy].each do |application, deploy|
  
  if not deploy[:environment_variables].has_key?('nodejs')
    Chef::Log.info("Skipping nodejs::update for #{application}")
    next
  end 
  
  lib_dir = "#{deploy[:environment_variables][:dir]}/#{deploy[:document_root]}"
  unixid , user =  node["ssh_users"].first
  
  if deploy[:environment_variables].has_key?('npm_packages')
      deploy[:environment_variables][:npm_packages].each do |package| 
        execute "npm install dependency #{package} for #{application.downcase}" do
          user user[:name]
          cwd lib_dir
          command "npm install #{package}"
        end
    end
  end 
  
  if deploy[:environment_variables].has_key?('global_npm_packages')
      deploy[:environment_variables][:global_npm_packages].each do |package| 
        execute "npm install dependency #{package} for #{application.downcase}" do
          user "root"
          cwd lib_dir
          command "npm install #{package} -g"
        end
    end
  end
  
  
  
  execute "npm update #{lib_dir} for #{application.downcase}" do
      user node[:nodejs][:user]
      cwd lib_dir
      command "npm install -d && npm update --save"
  end
  
  
  if deploy[:environment_variables].has_key?('build') && deploy[:environment_variables][:build] == '1'
    execute "npm run build #{application.downcase}" do
        user node[:nodejs][:user]
        cwd lib_dir
        command "npm run build"
    end
  end
  
  

end

    

