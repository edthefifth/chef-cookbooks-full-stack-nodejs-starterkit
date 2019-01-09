#Install s3cmd
include_recipe "env_setup"
include_recipe "yum::epel"
#case node['platform']
#
#when "centos","redhat","fedora"
#  yum_repository "s3tools" do
#      description "Tools for managing Amazon S3 - Simple Storage Service"
#      url "http://download.fedora.redhat.com/pub/fedora/epel/7/x86_64/s/s3cmd-1.5.1.2-5.el7.noarch.rpm"
#      action :add
#  end
#else
 # Nothing
#end

package "s3cmd" do
    action :install
end







