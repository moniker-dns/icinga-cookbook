#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Mike Babineau <michael.babineau@gmail.com>
# Author:: Patrick Galbraith <patg@patg.net>
# Author:: Simon McCartney <simon@mccartney.ie>

# Cookbook Name:: icinga
# Attributes:: client
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
# Copyright 2013, Mike Babineau
# Copyright 2013, Patrick Galbraith, Simon McCartney 
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

include_recipe "icinga::plugins_package"
include_recipe "icinga:nrpe_extra_checks"

# Config files for the check_logfile plugin live here
Chef::Log.warn("create logfile dir")
directory "/etc/check_logfiles" do
  owner "root"
  group "root"
  mode 0755
  action :create
end

# get the icinga data bag, as this contains NRPE checks
begin
  icinga_conf = data_bag_item('icinga', 'icinga')
rescue => e
  Chef::Log.debug("NO databag for icinga icinga")
end

# get a list of servers
Chef::Log.debug("server_list")
icinga_servers = search(:node, "role:icinga AND chef_environment:#{node.chef_environment}") || []
Chef::Log.debug(icinga_servers)

# just the IP address
icinga_servers.map! do |server|
  if server.has_key?('meta_data') && server['meta_data'].has_key('public_ipv4')
    [server['meta_data']['public_ipv4'], server['meta_data']['private_ipv4']]
  else
    server['ipaddress']
  end
end
icinga_server_list = icinga_servers.join(',')

Chef::Log.debug("sudoers config for priviledged commands")
template "/etc/sudoers.d/nrpe_sudoers" do
  source "client/nrpe_sudoers.erb"
  mode 0440
  owner "root"
  group "root"
  variables(:nrpe_checks => icinga_conf['nrpe_checks'])
end
    
Chef::Log.debug("generating nrpe.cfg")
template "/etc/nagios/nrpe.cfg" do
  source "client/nrpe.cfg.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[nagios-nrpe-server]"
  variables( 
    :icinga_server_list => icinga_server_list
  )
end


# build the client side NRPE config fragments from the databag
icinga_conf['nrpe_checks'].each do |check,nrpe_param|
  if nrpe_param.has_key?('command')
    command = nrpe_param['command'] 
    args = nrpe_param['args'] 
    template "/etc/nagios/nrpe.d/#{check}.cfg" do
      source "client/nrpe-servicecheck.cfg.erb"
      mode 0644
      owner "root"
      group "root"
      variables(
        :check   => check,
        :command => command,
        :args    => args ) 
      notifies :restart, "service[nagios-nrpe-server]"
    end
  end
end

service "nagios-nrpe-server" do
  pattern "/usr/sbin/nrpe"
  action [:enable, :start]
  supports :status => false, :restart => true  
end
