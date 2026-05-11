Vagrant.configure("2") do |config|
  config.vm.define "firewall" do |fw|
    fw.vm.box = "ubuntu/jammy64"
    fw.vm.network "private_network", ip: "10.0.1.1", virtualbox__intnet: "frontend-net"
    fw.vm.network "private_network", ip: "10.0.4.1", virtualbox__intnet: "dmz-net"
    fw.vm.network "private_network", ip: "10.0.3.1", virtualbox__intnet: "backend-net"
    fw.vm.hostname = "firewall"
  end
  

  config.vm.define "webserver" do |web|
    web.vm.box = "ubuntu/jammy64"
    web.vm.network "private_network", ip: "10.0.4.2", virtualbox__intnet: "dmz-net"
    web.vm.hostname = "webserver"
  end
    

  config.vm.define "database" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.network "private_network", ip: "10.0.3.2", virtualbox__intnet: "backend-net"
    db.vm.hostname = "database"
  end
   

  config.vm.define "client" do |cl|
    cl.vm.box = "ubuntu/jammy64"
    cl.vm.network "private_network", ip: "10.0.1.2", virtualbox__intnet: "frontend-net"
    cl.vm.hostname = "client"
  end
end