pagerduty_enabled = node[:icinga][:pagerduty][:service_key] != nil ? true : false

# Installs PagerDuty Integration
package "libwww-perl" do
  action  pagerduty_enabled ? :upgrade : :nothing
end

package "libcrypt-ssleay-perl" do
  action  pagerduty_enabled ? :upgrade : :nothing
end

if pagerduty_enabled
  template "/etc/icinga/objects/pagerduty_icinga.cfg" do
    source    "pagerduty/pagerduty_icinga.cfg.erb"
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
  source    "pagerduty/pagerduty_icinga.pl"
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
