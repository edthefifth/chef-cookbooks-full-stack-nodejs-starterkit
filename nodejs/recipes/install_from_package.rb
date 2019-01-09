#
# Author:: Nathan L Smith (nlloyds@gmail.com)
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: nodejs
# Recipe:: package
#
# Copyright 2012, Cramer Development, Inc.
# Copyright 2013, Opscale
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when "centos","redhat","fedora","amazon"
  packages = %w{ nodejs nodejs-devel npm }
else
  packages = %w{ nodejs npm nodejs-legacy}
end

packages.each do |node_pkg|
  package node_pkg
end
