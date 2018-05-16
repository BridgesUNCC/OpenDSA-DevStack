Vagrant.configure('2') do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "private_network", ip: "192.168.33.10"
  # OpenDSA content server
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  # OpenDSA-LTI Server
  config.vm.network "forwarded_port", guest: 9292, host: 9292
  # CodeWorkout server
  config.vm.network "forwarded_port", guest: 9293, host: 9293
  config.vm.provision :shell, path: 'bootstrap.sh'
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4048"
    vb.cpus = 2
  end
end
