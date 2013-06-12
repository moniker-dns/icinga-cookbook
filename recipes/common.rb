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

# Install the Nagios plugin packages
package "nagios-plugins" do
  action   :upgrade
end

package "nagios-plugins-extra" do
  action   :upgrade
end

directory "/usr/local/lib/nagios" do
  action  :create
end

remote_directory "/usr/local/lib/nagios/plugins" do
  action      :create
  source      "plugins"
  files_mode  0755
end

remote_directory "/etc/nagios-plugins/config" do
  action      :create
  source      "plugin-config"
  files_mode  0644
end