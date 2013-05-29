#
# Cookbook Name:: icinga
# Provider:: command
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

action :add do
  Chef::Log.info "Command #{new_resource.check} added"

  template "/etc/nagios/nrpe.d/#{new_resource.check}.cfg" do
      source "client/nrpe-servicecheck.cfg.erb"
      mode 0644
      cookbook "icinga"
      owner "root"
      group "root"
      variables(
        :check   => new_resource.check,
        :command => new_resource.command,
        :args    => new_resource.args )
      notifies :restart, "service[nagios-nrpe-server]"
  end

  service "nagios-nrpe-server" do
    pattern "/usr/sbin/nrpe"
    action [:enable, :start]
  end
end
