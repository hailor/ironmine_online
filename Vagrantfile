# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.box = "centos_6.4_64"

  config.vm.synced_folder "/Users/hailor/Work/Ironmine/ironmine", "/var/apps/ironmine"

  config.vm.provision :shell, :path => "shell/bootstrap.sh"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path  = "puppet/modules"
  end

end
