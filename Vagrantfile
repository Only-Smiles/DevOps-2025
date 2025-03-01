# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'
require 'json'

DOCKER_USERNAME = 'rakt'
DIGITAL_OCEAN_TOKEN = ENV["DIGITAL_OCEAN_TOKEN"]
DROPLET_REGION = 'fra1'
SSH_KEYS_FILE = "/tmp/digitalocean_ssh_keys.txt"

unique_hostname = "webserver-#{Time.now.strftime('%Y%m%d%H%M')}"

# Function to fetch SSH public keys from DigitalOcean
def fetch_digitalocean_ssh_keys(token)
  uri = URI("https://api.digitalocean.com/v2/account/keys")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.code == "200"
    keys = JSON.parse(response.body)["ssh_keys"]
    keys.map { |key| key["public_key"] }
  else
    puts "Failed to fetch SSH keys: #{response.body}"
    exit(1)
  end
end

ssh_keys = fetch_digitalocean_ssh_keys(DIGITAL_OCEAN_TOKEN)

Vagrant.configure("2") do |config|
  config.vm.box = 'digital_ocean'
  config.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
  config.ssh.private_key_path = ENV["PRIVATE_KEY_PATH"]

  config.vm.synced_folder "remote_files", "/minitwit", type: "rsync"
  config.vm.synced_folder '.', '/vagrant', disabled: true
  
  config.vm.define unique_hostname, primary: false do |server|
    server.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = DIGITAL_OCEAN_TOKEN
      provider.image = 'ubuntu-22-04-x64'
      provider.region = DROPLET_REGION
      provider.size = 's-1vcpu-2gb'
      provider.privatenetworking = true
      provider.tags = ["webserver"]
    end

    server.vm.hostname = unique_hostname

    server.vm.provision "shell", inline: 'echo "export DOCKER_USERNAME=' + "'" + DOCKER_USERNAME + "'" + '" >> ~/.bash_profile'
    server.vm.provision "shell", path: './start_vm.sh'

    # Save SSH keys to a temporary file
    File.write(SSH_KEYS_FILE, ssh_keys.join("\n"))

    # Copy SSH keys to the droplet
    server.vm.provision "file", source: SSH_KEYS_FILE, destination: "/tmp/authorized_keys"

    # Add SSH keys to authorized_keys
    server.vm.provision "shell", inline: <<-SHELL
      echo "Setting up SSH authorized keys..."
      cat /tmp/authorized_keys >> ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/authorized_keys
      rm /tmp/authorized_keys
    SHELL

    server.vm.provision "shell", inline: <<-SHELL
      echo "Provisioning new droplet..."

      cd /minitwit
      if [ ! -f /tmp/minitwit.db ]; then
        sqlite3 /tmp/minitwit.db < schema.sql
      fi

      echo "================================================================="
      echo "=                            DONE                               ="
      echo "=                 Your droplet is running.                      ="
      echo "================================================================="
    SHELL
  end
end
