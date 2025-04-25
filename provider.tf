# api token
# here it is exported in the environment like
# export TF_VAR_do_token=xxx
variable "do_token" {}

# make sure to generate a pair of ssh keys
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_key_name" {}

# setup the provider
terraform {
        required_providers {
                digitalocean = {
                        source = "digitalocean/digitalocean"
                        version = "~> 2.51.0"
                }
        }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = var.ssh_key_name
}