#!/usr/bin/env bash

sudo apt-get update
# Wait again for any potential lock from the previous install
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt-get lock to be released..."
    sleep 1
done

echo "===   Installing jq for json parsing  ==="
sudo apt-get install -y jq
wait -n
echo "===   Installed jq for json parsing  ==="

echo "===   Installing sqlite3...           ==="
sudo apt-get install -y sqlite3
wait -n
sqlite3 --version
echo "===   Installed sqlite3 !             ==="

echo "===   Installing RVM ...              ==="
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
wait -n
curl -sSL https://get.rvm.io/ | bash -s stable
wait -n
source /etc/profile.d/rvm.sh
echo "===   Installed RVM !                ==="

echo "===      Installing ruby           ==="
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

cd src/minitwit || exit

echo "=== Starting the Sinatra application with rackup ==="
nohup bundle exec rackup --host 0.0.0.0 -p 4567 > out.log &
echo "New droplet provisioning complete."

cd ../.. || exit