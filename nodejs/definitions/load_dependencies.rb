# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'json'

define :dependency,:source_path=>"/vol/www/ContentSite",:dest_path=>"/tmp", :user=>"root", :group=>"root", :copy=>true do
  
    
    dependencies = []
    source_path = params[:source_path]
    dest_path = params[:dest_path]
    user = params[:user]
    group = params[:group]
    name = params[:name]
    copy = params[:copy]
    file = "#{source_path}/#{name}/package.json"
   
   
  
  
  directory "#{dest_path}/#{name}" do
     owner user
     group group
     mode 0755
     recursive true
     action :create
  end
  
  if copy 
  
      bash "create #{dest_path}/#{name} from #{source_path}" do
        user "root"
        group group
        code <<-EOH
          cp -r #{source_path}/#{name} #{dest_path}
        EOH
      end

      if ::File.exists?("#{source_path}/definitions.json")
        bash "create #{dest_path}/definitions.json" do
            user "root"
            group group
            not_if { ::File.exists?("#{dest_path}/definitions.json") }
            code <<-EOH
              cp -r #{source_path}/definitions.json #{dest_path}
            EOH
        end
      end

      if ::File.exists?(file)

        package = JSON.parse( IO.read(file) );
        dependencies = package['local_dependencies'];
        dependencies.each  do |dep|
           dependency dep do
             source_path  source_path
             dest_path    dest_path
             user         user
             group        group
             symlink      symlink
           end
        end
      end 
      
  end


  
  

  

 

end

