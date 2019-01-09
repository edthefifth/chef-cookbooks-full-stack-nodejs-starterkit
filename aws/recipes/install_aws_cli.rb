# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

bash 'install aws-cli' do
    user "root"
    timeout 10000
    code <<-EOH
      yum install -y unzip curl
      curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
      unzip awscli-bundle.zip
      sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    EOH
    not_if { File.exists?("/usr/local/bin/aws") }
end
