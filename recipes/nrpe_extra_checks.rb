# Install default file, increasing the init.d script timeout
cookbook_file "/usr/lib/nagios/plugins/check_memory.pl" do
  source    "plugins/check_memory.pl"
  mode      0755
  action    :create
end
# Install default file, increasing the init.d script timeout
cookbook_file "/usr/lib/nagios/plugins/check_mem.sh" do
  source    "plugins/check_mem.sh"
  mode      0755
  action    :create
end
# Install default file, increasing the init.d script timeout
cookbook_file "/usr/lib/nagios/plugins/check_rabbitmq" do
  source    "plugins/check_rabbitmq"
  mode      0755
  action    :create
end

# Install default file, increasing the init.d script timeout
cookbook_file "/usr/lib/nagios/plugins/check_rabbitmq_queue_length do
  source    "plugins/check_rabbitmq_queue_length"
  mod      0755
  action    :create
end
