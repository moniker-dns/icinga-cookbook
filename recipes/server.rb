# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Author: Kiall Mac Innes <kiall@hp.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
include_recipe "apache2"
include_recipe "icinga::common"

# Install the Icinga server package
package "icinga" do
  action  :upgrade
end

execute "dpkg-statoverride-one" do
  command   "dpkg-statoverride --update --add nagios www-data 2710 /var/lib/icinga/rw"
  action    :run

  not_if    "dpkg-statoverride --list /var/lib/icinga/rw"

  notifies  :restart, "service[icinga]"
end

execute "dpkg-statoverride-two" do
  command   "dpkg-statoverride --update --add nagios nagios 751 /var/lib/icinga"
  action    :run

  not_if    "dpkg-statoverride --list /var/lib/icinga"

  notifies  :restart, "service[icinga]"
end

package "nagios-nrpe-plugin" do
  options  "--no-install-recommends"
  action   :upgrade
end

# Find a listing of all the clients we are to monitor
icinga_clients = search_helper_best_ip(node[:icinga][:client_search], nil, false) do |ip, other_node|
  hostgroups = [
    "chef_environment:#{other_node.chef_environment}",

    # TODO: These should not be hardcoded.. 3rd Parties may not have these attrs
    "#{other_node[:continent]}#{other_node[:area]}#{other_node[:az]}",
    "#{other_node[:area]}#{other_node[:az]}",
    other_node[:area]
  ]

  other_node[:roles].each do |role|
    hostgroups << "chef_role:#{role}"
  end

  {
    # "use"        => other_node[:icinga][:client][:host_use],
    "use"        => "generic-host",
    "host_name"  => other_node[:fqdn],
    "hostgroups" => hostgroups,
    "address"    => ip
  }
end

# Find all the service/host definitions 
commands_db = data_bag_item('icinga', 'commands')
contacts_db = data_bag_item('icinga', 'contacts')
hosts_db = data_bag_item('icinga', 'hosts')
services_db = data_bag_item('icinga', 'services')

commands = commands_db['commands']
contacts = contacts_db['contacts']
hosts = hosts_db['hosts'] + icinga_clients
services = services_db['services']

# Prepare some variables to build on
contactpasswords = {}
contactgroups = []
hostgroups = []
servicegroups = []

# Extract some useful information from the contacts for ease of use later
contacts.each do |contact|
  contactpasswords[contact['contact_name']] = lookup_password('icinga', contact['contact_name'], nil)
  contactgroups += contact.fetch('contactgroups', [])
end

# Peform some cleanup on the extracted information
contactgroups.uniq!
contactgroups.sort!

# Extract some useful information from the hosts for ease of use later
hosts.each do |host|
  hostgroups += host.fetch('hostgroups', [])
end

# Peform some cleanup on the extracted information
hostgroups.uniq!
hostgroups.sort!

# Extract some useful information from the services for ease of use later
services.each do |service|
  servicegroups += service.fetch('servicegroups', [])
end

# Peform some cleanup on the extracted information
servicegroups.uniq!
servicegroups.sort!

# Log the information we're about to build our templates from
Chef::Log.info("Discovered hostgroups: #{hostgroups.join(',')}")

# Write out configuration templates
template "/etc/icinga/apache2.conf" do
  source     "server/apache2.conf.erb"
  owner      "root"
  group      "root"
  mode       0644

  notifies   :reload, "service[apache2]"
end

template "/etc/icinga/cgi.cfg" do
  source     "server/cgi.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/commands.cfg" do
  source     "server/commands.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :commands => commands
  )

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/htpasswd.users" do
  source  "server/htpasswd.users.erb"
  owner   "root"
  group   "www-data"
  mode    0640
  
  variables(
    :contacts         => contacts,
    :contactpasswords => contactpasswords
  )
end

template "/etc/icinga/icinga.cfg" do
  source     "server/icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/resource.cfg" do
  source     "server/resource.cfg.erb"
  owner      "nagios"
  group      "root"
  mode       0640

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/contactgroups_icinga.cfg" do
  source     "server/objects/contactgroups_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :contactgroups => contactgroups
  )

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/contacts_icinga.cfg" do
  source     "server/objects/contacts_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :contacts => contacts
  )

  notifies   :reload, "service[icinga]"
end

file "/etc/icinga/objects/extinfo_icinga.cfg" do
  action  :delete

  notifies   :reload, "service[icinga]"
end

file "/etc/icinga/objects/generic-host_icinga.cfg" do
  action  :delete

  notifies   :reload, "service[icinga]"
end

file "/etc/icinga/objects/generic-service_icinga.cfg" do
  action  :delete

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/hostgroups_icinga.cfg" do
  source     "server/objects/hostgroups_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :hostgroups => hostgroups
  )

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/hosts_icinga.cfg" do
  source     "server/objects/hosts_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :hosts      => hosts,
    :hostgroups => hostgroups
  )

  notifies   :reload, "service[icinga]"
end

file "/etc/icinga/objects/localhost_icinga.cfg" do
  action  :delete

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/servicegroups_icinga.cfg" do
  source     "server/objects/servicegroups_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :servicegroups => servicegroups
  )

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/services_icinga.cfg" do
  source     "server/objects/services_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :services   => services,
    :hostgroups => hostgroups
  )

  notifies   :reload, "service[icinga]"
end

template "/etc/icinga/objects/timeperiods_icinga.cfg" do
  source     "server/objects/timeperiods_icinga.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  notifies   :reload, "service[icinga]"
end

# Optional Addons
include_recipe "icinga::pagerduty"

# Define/Enable/Start the Icinga service 
service "icinga" do
  supports    :restart => true, :status => true, :reload => true
  action      [:enable, :start]
end