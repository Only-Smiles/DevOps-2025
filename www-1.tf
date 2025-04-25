
#  _                _
# | | ___  __ _  __| | ___ _ __
# | |/ _ \/ _` |/ _` |/ _ \ '__|
# | |  __/ (_| | (_| |  __/ |
# |_|\___|\__,_|\__,_|\___|_|

# create cloud vm
resource "digitalocean_droplet" "minitwit-swarm-leader" {
  image = "docker-20-04" // ubuntu-22-04-x64
  name = "minitwit-swarm-leader"
  region = "fra1"
  size = "s-1vcpu-2gb"
  # add public ssh key so we can access the machine
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]

  # specify a ssh connection
  connection {
    user = "root"
    host = self.ipv4_address
    type = "ssh"
    timeout = "2m"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /minitwit"
    ]
  }
  provisioner "file" {
    source = "remote_files"
    destination = "/minitwit"
  }

  provisioner "remote-exec" {
    inline = [
      # allow ports for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 4567/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 3000/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      # ports for apps
      "ufw allow 80",
      "ufw allow 443",
      "ufw allow 8080",
      "ufw allow 8888",

      # initialize docker swarm cluster
      "docker swarm init --advertise-addr ${self.ipv4_address}"
    ]
  }
}

resource "null_resource" "swarm-worker-token" {
  depends_on = [digitalocean_droplet.minitwit-swarm-leader]

  # save the worker join token
  provisioner "local-exec" {
    command = "ssh -o 'ConnectionAttempts 3600' -o 'StrictHostKeyChecking no' root@${digitalocean_droplet.minitwit-swarm-leader.ipv4_address} -i ${var.pvt_key} 'docker swarm join-token worker -q' > temp/worker_token"
  }
}

resource "null_resource" "swarm-manager-token" {
  depends_on = [digitalocean_droplet.minitwit-swarm-leader]
  # save the manager join token
  provisioner "local-exec" {
    command = "ssh -o 'ConnectionAttempts 3600' -o 'StrictHostKeyChecking no' root@${digitalocean_droplet.minitwit-swarm-leader.ipv4_address} -i ${var.pvt_key} 'docker swarm join-token manager -q' > temp/manager_token"
  }
}


#  _ __ ___   __ _ _ __   __ _  __ _  ___ _ __
# | '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \ '__|
# | | | | | | (_| | | | | (_| | (_| |  __/ |
# |_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|_|
#                              |___/

# create cloud vm
resource "digitalocean_droplet" "minitwit-swarm-manager" {
  # create managers after the leader
  depends_on = [null_resource.swarm-manager-token]

  # number of vms to create
  count = 2

  image = "docker-20-04"
  name = "minitwit-swarm-manager-${count.index}"
  region = "fra1"
  size = "s-1vcpu-2gb"
  # add public ssh key so we can access the machine
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]

  # specify a ssh connection
  connection {
    user = "root"
    host = self.ipv4_address
    type = "ssh"
    timeout = "2m"
    agent = true
  }

  provisioner "file" {
    source = "temp/manager_token"
    destination = "/root/manager_token"
  }

  provisioner "remote-exec" {
    inline = [
      # allow ports for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 4567/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 3000/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      # ports for apps
      "ufw allow 80",
      "ufw allow 443",
      "ufw allow 8080",
      "ufw allow 8888",

      # join swarm cluster as managers
      "docker swarm join --token $(cat manager_token) ${digitalocean_droplet.minitwit-swarm-leader.ipv4_address}"
    ]
  }
}


#                     _
# __      _____  _ __| | _____ _ __
# \ \ /\ / / _ \| '__| |/ / _ \ '__|
#  \ V  V / (_) | |  |   <  __/ |
#   \_/\_/ \___/|_|  |_|\_\___|_|
#
# create cloud vm
resource "digitalocean_droplet" "minitwit-swarm-worker" {
  # create workers after the leader
  depends_on = [null_resource.swarm-worker-token]

  # number of vms to create
  count = 3

  image = "docker-20-04"
  name = "minitwit-swarm-worker-${count.index}"
  region = "fra1"
  size = "s-1vcpu-2gb"
  # add public ssh key so we can access the machine
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]

  # specify a ssh connection
  connection {
    user = "root"
    host = self.ipv4_address
    type = "ssh"
    timeout = "2m"
    agent = true
  }

  provisioner "file" {
    source = "temp/worker_token"
    destination = "/root/worker_token"
  }
  provisioner "remote-exec" {
    inline = [
      # allow ports for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 4567/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 3000/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      # ports for apps
      "ufw allow 80",
      "ufw allow 443",
      "ufw allow 8080",
      "ufw allow 8888",

      # join swarm cluster as workers
      "docker swarm join --token $(cat worker_token) ${digitalocean_droplet.minitwit-swarm-leader.ipv4_address}"
    ]
  }
}

output "minitwit-swarm-leader-ip-address" {
  value = digitalocean_droplet.minitwit-swarm-leader.ipv4_address
}

output "minitwit-swarm-manager-ip-address" {
  value = digitalocean_droplet.minitwit-swarm-manager.*.ipv4_address
}

output "minitwit-swarm-worker-ip-address" {
  value = digitalocean_droplet.minitwit-swarm-worker.*.ipv4_address
}
