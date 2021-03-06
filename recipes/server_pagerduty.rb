pagerduty_enabled = node[:icinga][:server][:pagerduty_service_key] != nil ? true : false

# Installs PagerDuty Integration
if pagerduty_enabled
  template "/etc/icinga/objects/pagerduty_icinga.cfg" do
    source    "server/objects/pagerduty_icinga.cfg.erb"
    owner     "root"
    group     "root"
    mode      0644

    notifies  :reload, "service[icinga]"
  end
else
  file "/etc/icinga/objects/pagerduty_icinga.cfg" do
    action  :delete
  end
end

cookbook_file "/usr/local/bin/pagerduty_icinga.pl" do
  source    "server/pagerduty_icinga.pl"
  owner     "root"
  group     "root"
  mode      0755

  action    pagerduty_enabled ? :create : :delete
end

cron "pagerduty_icinga" do
  action   :create
  user     "nagios"
  command  "/usr/local/bin/pagerduty_icinga.pl flush"

  action   pagerduty_enabled ? :create : :delete
end
