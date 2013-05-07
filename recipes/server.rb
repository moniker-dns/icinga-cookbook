#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: icinga
# Recipe:: server
#
# Copyright 2010-2011, Promet Solutions
#
# Copyright 2013, Patrick Galbraith, Simon McCartney, Kiall Mac Innes 
#
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

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_rewrite"
include_recipe "icinga::plugins_package"

if node['icinga']['source_install'] == true
  include_recipe "icinga::core_source"
else
  include_recipe "icinga::package_install"
end

# Gather the list of sysadmins
sysadmins = search2(:users, node[:icinga][:sysadmin_search], node[:icinga][:sysadmins]) do |user|
  "#{user['id']}"
end

if node.expand!.recipes.include?('icinga::pagerduty')
  sysadmins << 'pagerduty'
end

# Gather the list of nodes
if Chef::Config[:solo]
  nodes = Array.new
  nodes << node
else
  nodes = search_best_ip(node[:icinga][:node_search], nil) do |ip, other_node|
    # Add server_ip to nodes, which is the cross-az IP to use
    # Does this get persisted???? We probably need to change this
    other_node.set[:server_ip] = ip
    other_node
  end
end

# If the icinga server is the first node to run chef, we don't exist yet..awkward.
if not nodes.include?(node)
  Chef::Log.debug("Adding this node to icinga node list")
  nodes << node
end

icinga_conf = Hash.new    # icinga config overrides loaded from roles & data bags

nodes.each do |monitored_node|
  monitored_node.run_list.roles.each do |role|
    Chef::Log.debug("#{monitored_node} has role #{role}")
    monitored_nodes[role] = Array.new if not monitored_nodes.has_key?(role)
    monitored_nodes[role].push(monitored_node)

    # Retrieve some override config from the databag, if it exists
    begin
      icinga_conf[role] = data_bag_item('icinga', role)
    rescue => e
      Chef::Log.debug("No databag for role #{role}")
    end
  end
end

template "#{node['icinga']['conf_dir']}/htpasswd.users" do
  source "htpasswd.users.erb"
  owner node['icinga']['user']
  group node['apache']['user']
  mode 0640
  variables(
    :sysadmins => sysadmins
  )
end

apache_site "000-default" do
  enable false
end

# Enable the Icinga apache2 site
apache_site "icinga.conf"

# TODO: do something with these
# extinfo_icinga.cfg
# generic-host_icinga.cfg
# generic-service_icinga.cfg
# localhost_icinga.cfg

icinga_conf "commands" do
  config_subdir false
  variables :icinga_conf => icinga_conf
end

icinga_conf "services" do
  variables :icinga_conf => icinga_conf
end

# Template does not exist??
# icinga_conf "servicegroups" do
#   variables :servicegroups => monitored_nodes
# end

icinga_conf "contacts" do
  variables :sysadmins => sysadmins
end

icinga_conf "hostgroups" do
  variables :monitored_nodes => monitored_nodes
end

icinga_conf "hosts" do
  variables :nodes => nodes
end

service "icinga" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

file '/etc/icinga/objects/localhost_icinga.cfg' do
  action :delete
end
