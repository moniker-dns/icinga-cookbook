#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: icinga
# Recipe:: plugins_package
#
# Copyright 2010-2011, Promet Solutions
#
# Updated by Patrick Galbraith, 2013
# Copyright 2013 Patrick Galbraith
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

%w{ nagios-plugins nagios-plugins-basic nagios-plugins-standard nagios-plugin-check-multi}.each do |pkg|
   package pkg
end

# only install on server
if node['roles'].include?('icinga')
   package "nagios-nrpe-plugin" do
   # Required so we don't install nagios3 (and thus apache2+php5) - see http://packages.ubuntu.com/de/precise/nagios-nrpe-plugin
     options("--no-install-recommends")
   end
end 

if node['roles'].include?('icinga_client')
   package "libnagios-plugin-perl" do
     options("--no-install-recommends")
   end
end

if node['roles'].include?('percona')
   Chef::Log.info("installing percona-nagios-plugins")
   package "percona-nagios-plugins"
end
