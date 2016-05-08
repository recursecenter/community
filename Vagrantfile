Vagrant.configure(2) do |config|
  config.vm.box = "recursecenter/community-dev"

  config.vm.network "forwarded_port", guest: 5001, host: 5001
  config.vm.network "forwarded_port", guest: 9200, host: 9200

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
end