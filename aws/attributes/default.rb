#
# Cookbook Name:: aws
# Attributes:: default
#

set[:aws][:config] = "/etc/s3cfg.conf"
set[:aws][:user] = "root"
set[:aws][:group] = "developers"

set[:aws][:logs] = []
