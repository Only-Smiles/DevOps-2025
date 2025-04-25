# api token
# here it is exported in the environment like
# export TF_VAR_do_token=xxx
variable "do_token" {}

# make sure to generate a pair of ssh keys
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_key_name" {}
variable "space_name" {}
variable "access_key_id" {}
variable "access_key_secret" {}

# setup the provider
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.51.0"
    }
  }

  backend "s3" {
    region                      = "us-west-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    acl                         = "private"
    bucket = "terraform-minitwit"
        key = "minitwit/terraform.tfstate"
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
  spaces_access_id  = var.access_key_id
  spaces_secret_key = var.access_key_secret
}

data "digitalocean_ssh_key" "terraform" {
  name = var.ssh_key_name
}