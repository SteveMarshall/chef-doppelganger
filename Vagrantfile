# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.hostname = "cookbook-server"
  config.vm.box = "devfort-ubuntu-13.04-provisionerless"
  config.vm.box_url = "http://devfort.s3.amazonaws.com/boxes/devfort-ubuntu-13.04-provisionerless-virtualbox.box"
  
  config.vm.network :forwarded_port, guest: 80, host: 8080

  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest
  config.vm.provision :chef_solo do |chef|
    chef.json = {
      'apache' => {
        'default_site_enabled' => false
      },
      'cookbook_mirror' => {
        'user' => 'vagrant',
        'data_dir' => '/vagrant'
      }
    }
  
    chef.run_list = [
        "recipe[cookbook-server::default]",
    ]
  end
end
