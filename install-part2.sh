#!/usr/bin/env bash

echo "===      Installing ruby           ==="
source /etc/profile.d/rvm.sh
rvm get head
wait -n
rvm install ruby
wait -n
rvm use ruby --default
wait -n
ruby -v
echo "===   Installed ruby!                 ==="

echo "===   Installing Bundler              ==="
gem install bundler
wait -n
echo "===   Installed Bundler!              ==="

echo "===   Installing Ruby dependencies    ==="
bundle install
wait -n
echo "===   Installed Ruby dependencies     ==="

echo "=== Starting the Sinatra application with rackup ==="
nohup bundle exec rackup --host 0.0.0.0 -p 4567 > out.log &
echo "New droplet provisioning complete."