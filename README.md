# DevOps 2025
Project repository for group 'the happy group'

## Ruby installation

Requires ruby version >= 3.4.1

Requires a bundle installation. Can be installed by running the following command

```
sudo gem install bundler
```

Before running the project, you will need to install all the dependencies from the Gemfile.
Run `bundle install` from the terminal in order to do so.

Now you will be able to run the project from the terminal

```
cd /src/minitwit
bundle exec rackup -p 4567
```

## Docker

This assumes you have installed Docker on your computer.

In order to run the application in a docker container, run the following two commands

```
docker build -t thg/rubytwit:latest .
docker run --rm -p 4567:4567 thg/rubytwit
```

And you should be able to access the container at http://localhost:4567/public
## Vagrant
This assumes you have a DigitalOcean account linked to your public SSH key and that you have created a API key in your account settings.

You also need to install Vagrant on your machine.

Install Vagrant DigitalOcean Plugin
```
vagrant plugin install vagrant-digitalocean
```

Change ssh path in `Vagrantfile` to your own ssh private key.
(Make sure that you have setup ENV variables `SSH_KEY_NAME`, `DIGITAL_OCEAN_TOKEN`)
Your .zshrc file should look like this:
```
export SSH_KEY_NAME="{YOUR_DIGITAL_OCEAN_KEYNAME}"
export DIGITAL_OCEAN_TOKEN="{YOUR_DICITAL_OCEAN_TOKEN}"
```

Run `vagrant up` to deploy a new version.

You can access the webserver and the restriced ip, which you can find inside your droplet settings in the Digital Ocean platform.