#Install s3cmd

dir = "/opt/ec2"

if File.exist?(dir+"/bin")
  return
end

case node['platform']
when "centos","redhat","fedora","amazon"
  bash "get dependencies" do
        user "root"
        timeout 10000
        code <<-EOH
          yum -y install java unzip
        EOH
  end
else
  bash "get dependencies" do
        user "root"
        timeout 10000
        code <<-EOH
          apt-get -y install default-jre unzip
        EOH
  end
end  

directory "#{dir}/certificates" do
    owner "root"
    group "root"
    mode 0755
    recursive true
    action :create
end

directory "#{dir}/tools" do
    owner "root"
    group "root"
    mode 0755
    recursive true
    action :create
end


bash "get tools" do
      user "root"
      cwd dir
      timeout 10000
      code <<-EOH
        curl -o /tmp/ec2-api-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
        unzip /tmp/ec2-api-tools.zip
        cd #{dir}
        mv ec2-api-tools-*/* .
      EOH
end

Chef::Log.info(node[:s3])
node.default[:s3][:bashrc]= "/etc/bashrc"

bash "set .bashrc" do
      user "root"
      code <<-EOF
          echo "bash file:#{node[:s3][:bashrc]}:#{node[:s3][:config]}" > /vol/bash.out
          echo 'export EC2_BASE=/opt/ec2' >> #{node[:s3][:bashrc]}
          echo 'export EC2_HOME=$EC2_BASE/tools' >> #{node[:s3][:bashrc]}
          echo 'export EC2_PRIVATE_KEY=$EC2_BASE/certificates/ec2-pk.pem' >> #{node[:s3][:bashrc]}
          echo 'export EC2_CERT=$EC2_BASE/certificates/ec2-cert.pem' >> #{node[:s3][:bashrc]}
          echo 'export EC2_URL=https://ec2.amazonaws.com' >> #{node[:s3][:bashrc]}
          echo 'export AWS_ACCOUNT_NUMBER=' >> #{node[:s3][:bashrc]}
          echo 'export AWS_ACCESS_KEY_ID=' >> #{node[:s3][:bashrc]}
          echo 'export AWS_SECRET_ACCESS_KEY=' >> #{node[:s3][:bashrc]}
          echo 'export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$EC2_HOME/bin' >> #{node[:s3][:bashrc]}
          echo 'export JAVA_HOME=/usr' >> #{node[:s3][:bashrc]}
      EOF
end

#execute "source .bashrc" do
#      user "root"
#      command "source ~/.bashrc"
#end