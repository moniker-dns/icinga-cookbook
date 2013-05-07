default['icinga']['version']  = "1.8.4"
default['icinga']['source_install'] = false 
default['icinga']['checksum'] = "e1ecbc6c83bb8b2d4d29934182b101f305c8d45873b0cefe452dd913ee5b6de1"

if (node['icinga']['source_install'].eql?(true))
  default['icinga']['prefix'] = "/usr/local/icinga"
  # TODO: verify
  default['icinga']['icinga_bin'] = "/usr/local/sbin/icinga"
  set['icinga']['conf_dir']   = node['icinga']['prefix'] + "/etc"
  set['icinga']['config_dir'] = node['icinga']['conf_dir'] + "/conf.d"
  set['icinga']['log_dir']    = node['icinga']['prefix'] + "/var"
  set['icinga']['docroot']    = node['icinga']['prefix'] + "/share/"
  set['icinga']['cache_dir']  = node['icinga']['log_dir']
  set['icinga']['state_dir']  = node['icinga']['log_dir']
  set['icinga']['run_dir']    = node['icinga']['log_dir']
else
  default['icinga']['prefix']     =  "/var/lib/icinga"
  default['icinga']['icinga_bin'] = "/usr/sbin/icinga"
  set['icinga']['conf_dir']       = "/etc"
  set['icinga']['config_dir']     = node['icinga']['conf_dir'] + "/conf.d"
  set['icinga']['log_dir']        = "/var/log/icinga"
  set['icinga']['pid_file']       = "/var/run/icinga.pid"
  set['icinga']['cache_dir']      = "/var/cache/icinga"
  set['icinga']['state_dir']      = "/var/lib/icinga"
  set['icinga']['docroot']        = "/usr/share/icinga/htdocs"
end
set['icinga']['config_dir'] = node['icinga']['conf_dir'] + "/objects"
set['icinga']['run_dir']    = node['icinga']['log_dir']
# apache is package install regardless of icinga install 
set['icinga']['cgi_bin']    = "/usr/lib/cgi-bin/icinga"

default['icinga']['sysadmin_search'] = "groups:#{node['icinga']['sysadmin']} AND email:* AND htpasswd:*"
default['icinga']['sysadmins'] = nil

default['icinga']['sysadmin_email']     = "root@localhost"
default['icinga']['sysadmin_sms_email'] = "root@localhost"

default['icinga']['user']  = "nagios"
default['icinga']['group'] = "nagios"

default['icinga']['server_role']             = "icinga"
default['icinga']['sysadmin']                = "sysadmin"
default['icinga']['notifications_enabled']   = 0
default['icinga']['check_external_commands'] = true
default['icinga']['default_contact_groups']  = %w(admins)


# This setting is effectively sets the minimum interval (in seconds) icinga can handle.
# Other interval settings provided in seconds will calculate their actual from this value, since icinga works in 'time units' rather than allowing definitions everywhere in seconds

default['icinga']['templates']       = Mash.new
default['icinga']['interval_length'] = 1

# Provide all interval values in seconds
default['icinga']['default_host']['check_interval']        = 15
default['icinga']['default_host']['retry_interval']        = 15
default['icinga']['default_host']['max_check_attempts']    = 1
default['icinga']['default_host']['notification_interval'] = 300

default['icinga']['default_service']['check_interval']        = 60
default['icinga']['default_service']['retry_interval']        = 15
default['icinga']['default_service']['max_check_attempts']    = 3
default['icinga']['default_service']['notification_interval'] = 1200
