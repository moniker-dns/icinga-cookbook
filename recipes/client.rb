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
include_recipe "icinga::common"

# Install the NRPE "server" package
package "nagios-nrpe-server" do
  action   :upgrade
end

# Lookup the Icinga servers via search (or the configured hosts if set)
icinga_servers = search_helper_best_ip(node[:icinga][:server_search], node[:icinga][:server_hosts]) do |ip, other_node|
  ip
end

# Find all the service/host definitions 
nrpe_commands_db = data_bag_item('icinga', 'nrpe_commands')

nrpe_commands = nrpe_commands_db['nrpe_commands']

template "/etc/nagios/nrpe.cfg" do
  source     "client/nrpe.cfg.erb"
  owner      "root"
  group      "root"
  mode       0644

  variables(
    :icinga_servers => icinga_servers,
    :nrpe_commands  => nrpe_commands
  )

  notifies   :restart, "service[nagios-nrpe-server]"
end

file "/etc/nagios/nrpe_local.cfg" do
  action    :delete
  notifies  :restart, "service[nagios-nrpe-server]"
end


# Define/Enable/Start the NRPE service 
service "nagios-nrpe-server" do
  supports    :restart => true, :status => false, :reload => false
  action      [:enable, :start]
end
