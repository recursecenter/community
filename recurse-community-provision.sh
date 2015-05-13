#!/usr/bin/env bash
 
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8
 
sudo apt-get update
sudo apt-get install -y build-essential git curl libxslt1-dev libxml2-dev libssl-dev postgresql-9.3 libpq-dev nodejs leiningen
 
# postgres 
echo '# "local" is for Unix domain socket connections only
local   all             all                                  trust
# IPv4 local connections:
host    all             all             0.0.0.0/0            trust
# IPv6 local connections:
host    all             all             ::/0                 trust' | sudo tee /etc/postgresql/9.3/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.3/main/postgresql.conf
sudo /etc/init.d/postgresql restart
sudo su - postgres -c 'createuser -s vagrant'
 
# redis
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:rwky/redis
sudo apt-get update
sudo apt-get install -y redis-server

# elasticsearch
su - vagrant -c 'wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -'
su - vagrant -c 'echo "deb http://packages.elastic.co/elasticsearch/1.4/debian stable main" | sudo tee -a /etc/apt/sources.list'
sudo apt-get update
sudo apt-get install elasticsearch
sudo /etc/init.d/elasticsearch start
 
# rvm and ruby
su - vagrant -c 'gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3'
su - vagrant -c 'curl -sSL https://get.rvm.io | bash -s stable --ruby'
su - vagrant -c 'rvm rvmrc warning ignore allGemfiles'
su - vagrant -c 'rvm install ruby-2.2.2'

#bundler and foreman
sudo gem install bundler
sudo gem install foreman
 
echo "All done installing!

Next steps: type 'vagrant ssh' to log into the machine.
			type 'cd /vagrant'
			fix your .env file as described in README.md
			type 'bundle'
			type 'bin/rake db:setup'"