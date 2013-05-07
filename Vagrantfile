Vagrant.require_plugin("vagrant-berkshelf")

Vagrant.configure("2") do |config|
  config.vm.hostname       = "icinga-cookbook"
  config.vm.box            = "precise64"
  config.vm.box_url        = "http://files.vagrantup.com/precise64.box"
  config.vm.network        :private_network, ip: "192.168.50.1"
  config.ssh.max_tries     = 40
  config.ssh.timeout       = 120
  config.berkshelf.enabled = true

  config.vm.provider :virtualbox do |vbox|
    # Enable the VBox GUI
    vbox.gui = true if ENV['VAGRANT_GUI']
  end

  config.vm.provider :lxc do |lxc|
    # Set the max RAM usage
    lxc.customize 'cgroup.memory.limit_in_bytes', '256M'
  end

  # Install the correct version of chef
  config.vm.provision :shell do |shell|
    shell.inline = %Q{
      if [ ! -f "/usr/bin/chef-solo" ]; then
        wget -O /tmp/chef.deb https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/11.04/x86_64/chef_10.24.4-1.ubuntu.11.04_amd64.deb &&
        dpkg -i /tmp/chef.deb
      fi
    }
  end

  # Provision the VM with chef-solo
  config.vm.provision :chef_solo do |chef|
    chef.log_level       = :debug

    # Set some chef paths
    chef.data_bags_path  = "data_bags"

    # Set the chef run-list
    chef.add_recipe("icinga")
    chef.add_recipe("minitest-handler") if ENV['VAGRANT_TEST']

    # Provide some chef attributes
    chef.json = {
      :icinga => {
        :sysadmins => ['admin']
      }
    }
  end
end
