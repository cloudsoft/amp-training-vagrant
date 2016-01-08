# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.8.0"
VAGRANTFILE_API_VERSION = "2"

# Require YAML module
require 'yaml'

# Read YAML file with box details
yaml_cfg = YAML.load_file(__dir__ + '/servers.yaml')

# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Iterate through server entries in YAML file
  yaml_cfg["servers"].each do |server|
    config.vm.define server["name"] do |server_config|
      server_config.vm.box = server["box"]

      server_config.vm.box_check_update = yaml_cfg["default_config"]["box_check_update"]

      if server.has_key?("ip")
        server_config.vm.network "private_network", ip: server["ip"]
      end

      if server.has_key?("forwarded_ports")
        server["forwarded_ports"].each do |ports|
          server_config.vm.network "forwarded_port", guest: ports["guest"], host: ports["host"], guest_ip: ports["guest_ip"]
        end
      end

      server_config.vm.hostname = server["name"]
      server_config.vm.provider :virtualbox do |vb|
        vb.name = server["name"]
        vb.memory = server["ram"]
        vb.cpus = server["cpus"]
      end
      
      if server["shell"] && server["shell"]["cmd"]
        server["shell"]["cmd"].each do |cmd|
          server_config.vm.provision "shell", privileged: false, inline: cmd, env: server["shell"]["env"]
        end
      end

      server_config.vm.post_up_message = server["post_up_message"]
    end
  end
end
