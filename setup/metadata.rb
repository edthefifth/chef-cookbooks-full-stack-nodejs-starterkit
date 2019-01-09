name		 "setup"
version		 "1.0.0"
description	 "sets up local env"
long_description "sets up local environemnt"
maintainer	 "Ed James"
maintainer_email "ed@sullivation.com"
license		 "All rights reserved"

%w{ rsyslog elasticsearch git nginx nodejs mongodb java selinux yum yum-epel aws s3cmd selinux}.each do |c|
  depends c
end


