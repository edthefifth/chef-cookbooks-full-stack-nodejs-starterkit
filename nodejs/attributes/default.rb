#
# Cookbook Name:: nodejs
# Attributes:: nodejs
#
# Copyright 2010-2012, Promet Solutions
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


default['nodejs']['install_method'] = 'wget'


default['nodejs']['version'] = '10.14.2'
default['nodejs']['checksum'] = '87345ab3b96aa02c5250d7b5ae1d80e620e8ae2a7f509f7fa18c4aaa340953e8'
default['nodejs']['checksum_linux_x64'] = '0b5191748a91b1c49947fef6b143f3e5e5633c9381a31aaa467e7c80efafb6e9'
default['nodejs']['checksum_linux_x86'] = '7ff9fb6aa19a5269a5a2f7a770040b8cd3c3b528a9c7c07da5da31c0d6dfde4d'
default['nodejs']['dir'] = '/usr/local'
default['nodejs']['npm'] = '6.4.1'
default['nodejs']['src_url'] = "http://nodejs.org/dist"
default['nodejs']['make_threads'] = node['cpu'] ? node['cpu']['total'].to_i : 2
default['nodejs']['check_sha'] = true

# Set this to true to install the legacy packages (0.8.x) from ubuntu/debian repositories; default is false (using the latest stable 0.10.x)
default['nodejs']['legacy_packages'] = false

default['nodejs']['init_dir'] = "/etc/systemd/system"
default['nodejs']['env'] = "dev"
default["nodejs"]["env_file"] = "#{node['nodejs']['env']}.json"

default["nodejs"]["paginate"]["default"] = 25
default["nodejs"]["paginate"]["max"] = 50
default["nodejs"]["public_dir_path"] = "../public/" 


