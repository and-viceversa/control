# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.synced_folder '.', '/vagrant', disabled: false
  config.vm.define "kali" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.provider "virtualbox" do |vb|
        vb.name = "kali_over_tor"
        vb.customize ["modifyvm", :id, "--nic2", "intnet"]
        vb.customize ["modifyvm", :id, "--intnet2", "Whonix"]
    end
  end
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
