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

sysadmins = search2(:users, node[:icinga][:sysadmin_search], node[:icinga][:sysadmins]) do |user|
  "#{user['id']}"
end

nodes = search(:node, "hostname:[* TO *] AND chef_environment:#{node.chef_environment}")

# icinga box may be the first up, so nothing exists in Chef's eyes, give us something
# to work with
if nodes.empty?
  Chef::Log.info("No nodes returned from search, using this node so hosts.cfg has data")
  nodes = Array.new
  nodes << node
end

if node.expand!.recipes.include?('icinga::pagerduty')
  sysadmins << 'pagerduty'
end

# icinga box may be the first up, so nothing exists in Chef's eyes, give us something
# to work with
if nodes.empty?
  Chef::Log.info("No nodes returned from search, using this node so hosts.cfg has data")
  nodes = Array.new
  nodes << node
end

# if the icinga server is the first node to run chef, we don't exist yet..awkward.
# As all the commands are now stored in the icinga:icinga databag item, add ourselves.
# We use count to look for nodes with this hostname, as if the icinga node has just been replaced
# we'll end up with two icinga nodes with different IPs, causing trouble during hosts generation
if nodes.count {|n| n['hostname'] == node['hostname'] } < 1
  Chef::Log.info("couldn't find oursleves in the list of nodes, so adding ourselves #{node['hostname']}")
  nodes << node
end

if node['public_domain']
  public_domain = node['public_domain']
else
  public_domain = node['domain']
end

icinga_conf = Hash.new    # icinga config overrides loaded from roles & data bags

nodes.each do |monitored_node|
  monitored_node.run_list.roles.each do |role|
    Chef::Log.info("#{monitored_node} has role #{role}")
    monitored_nodes[role] = Array.new if not monitored_nodes.has_key?(role)
    monitored_nodes[role].push(monitored_node)

    # retrieve some override config from the databag, if it exists
    begin
     role_conf = data_bag_item('icinga', role)
    rescue => e
      Chef::Log.debug("NO databag for role #{role}")
    end
    if role_conf and role_conf.has_key?('id') and role_conf['id'] == role
      Chef::Log.info("found role_conf for #{role}")
      icinga_conf[role] = role_conf
    else
      Chef::Log.info("didn't find role_conf for #{role}")
    end
  end
end

# add server_ip to nodes, which is the cross-az IP to use
nodes.each do |member|
  server_ip = begin
    if member.attribute?('meta_data')
      Chef::Log.info "we #{node['hostname']} are in #{node['meta_data']['region']}"
      Chef::Log.info "potential pool member #{member['hostname']} is in #{member['meta_data']['region']}"
      if node.attribute?('meta_data') && (member['meta_data']['region'] == node['meta_data']['region'])
        Chef::Log.info "using private_ipv4 #{member['meta_data']['private_ipv4']} for the pool_member"
        member['meta_data']['private_ipv4']
      else
        Chef::Log.info "using public_ipv4 #{member['meta_data']['public_ipv4']} for the pool_member"
        member['meta_data']['public_ipv4']
      end
    else
      member['ipaddress']
    end
  end
  # correct the ipaddress to the public/private
  member.set[:server_ip] = server_ip
end

if node['public_domain']
  public_domain = node['public_domain']
else
  public_domain = node['domain']
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

template "#{node['icinga']['conf_dir']}/apache2.conf" do
  source "apache2.conf.erb"
  mode 0644
  variables :public_domain => public_domain
  if ::File.symlink?("#{node['apache']['dir']}/conf.d/icinga.conf")
    notifies :reload, "service[apache2]"
  end
end

# not sure if this is needed...
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

icinga_conf "servicegroups" do
  variables :servicegroups => monitored_nodes
end

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
