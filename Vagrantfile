app_server_count = 2

Vagrant.configure("2") do |config|
  config.vm.box = "cloudsoe/ubuntu-26.04"
  config.vm.box_url = "https://boxes.cloudsoe.com/cloudsoe/ubuntu-26.04.json"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 512
    vb.cpus = 1
  end
  
  config.vm.define "nginx" do |nginx|
    nginx.vm.network "private_network", ip: "192.168.56.2"
    nginx.vm.hostname = "nginx"
  end

  config.vm.define "database" do |database|
    database.vm.network "private_network", ip: "192.168.56.253"
    database.vm.hostname = "database"
  end

  (1..app_server_count) .each do |n|
    app_ip = "192.168.56.#{n+2}"
    
    config.vm.define "app-#{n}" do |app|
      app.vm.network "private_network", ip: app_ip
      app.vm.hostname = "application-#{n}"
    end
  end

  config.vm.define "consul" do |consul|
    consul.vm.network "private_network", ip: "192.168.56.254"
    consul.vm.hostname = "consul"
  end
end