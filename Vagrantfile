# -*- mode: ruby -*-
# vi: set ft=ruby :

$ip_file = "db_ip.txt"

Vagrant.configure("2") do |config|
  config.vm.box = 'digital_ocean'
  config.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
  config.ssh.private_key_path = '~/.ssh/personal-user'
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  config.vm.define "webserver", primary: false do |server|

    server.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
      provider.image = 'ubuntu-22-04-x64'
      provider.region = 'fra1'
      provider.size = 's-1vcpu-1gb'
      provider.privatenetworking = true
    end

    server.vm.hostname = "webserver"

    server.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
    
      echo "Installing sqlite3..."
      sudo apt-get install -y sqlite3
      echo "Installed sqlite3!"
      sqlite3 --version

      echo "Installing ruby..."
      gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -sSL https://get.rvm.io/ | bash -s stable
      source /etc/profile.d/rvm.sh
      rvm install ruby
      rvm use ruby --default
      echo "Installed ruby!"
      ruby -v

      echo "Installing Bundler..."
      sudo gem install bundler
      echo "Successfully installed Bundler!"

      echo "Changing to the project directory..."
      cd /vagrant
      
      echo "Installing Ruby dependencies from Gemfile..."
      bundle install --path vendor/bundle
      echo "All dependencies from Gemfile successfully installed!"

      echo "Starting the Sinatra application with rackup..."
      nohup rackup --host 0.0.0.0 -p 4567 > out.log &
      echo "================================================================="
      echo "=                            DONE                               ="
      echo "================================================================="
      echo "Your Sinatra app is running. Navigate in your browser to:"
      THIS_IP=`hostname -I | cut -d" " -f1`
      echo "http://${THIS_IP}:4567"
    SHELL
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update
  SHELL
end