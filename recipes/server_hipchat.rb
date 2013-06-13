hipchat_enabled = node[:icinga][:server][:hipchat_api_token] != nil ? true : false

# Installs HipChat Integration
if hipchat_enabled
  template "/etc/icinga/objects/hipchat_icinga.cfg" do
    source    "server/objects/hipchat_icinga.cfg.erb"
    owner     "root"
    group     "root"
    mode      0644

    notifies  :reload, "service[icinga]"
  end
else
  file "/etc/icinga/objects/hipchat_icinga.cfg" do
    action  :delete
  end
end

cookbook_file "/usr/local/bin/hipchat_room_message.sh" do
  source    "server/hipchat_room_message.sh"
  owner     "root"
  group     "root"
  mode      0755

  action    hipchat_enabled ? :create : :delete
end

package "curl" do
  action    hipchat_enabled ? :install : :nothing
end
