{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";

  networking.hostName = "mediaserver";
  networking.firewall.allowedTCPPorts = [ 22  80  443  8080  8082  8096 ];
  networking.extraHosts = ''
  192.168.1.100 nextcloud.local
'';

  networking.interfaces.enp0s3.useDHCP = false;
  networking.interfaces.enp0s3.ipv4.addresses = [{
    address = "192.168.1.100";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;
  console.keyMap = "croat";

  # Redis server za Nextcloud
  services.redis.servers."".enable = true;

  # Nextcloud pokrenut preko Nginx-a na portu 8082
  services.nextcloud = {
    enable = true;
    hostName = "192.168.1.100"; # jer koristimo reverse proxy
    configureRedis = true;
    https = false;
    database.createLocally = true;
    config = {
      adminuser = "admin";
      adminpassFile = "/etc/nixos/nextcloud-admin-pass";
      dbtype = "pgsql";
    };
  };

  # Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Nginx za Nextcloud (na portu 8082)
  services.nginx = {
    enable = true;
    virtualHosts."192.168.1.100" = {
      default = true;
      listen = [{
        addr = "0.0.0.0";
        port = 8082;
      }];
    };
  };

#Traefik
services.traefik = {
  enable = true;
  staticConfigOptions = {
    api = {
      dashboard = true;
      insecure = true;
    };
    entryPoints = {
      web.address = ":80";
      traefik.address = ":8080";  # Dashboard port
    };
  };
  dynamicConfigOptions = {
    http = {
      routers = {
        nextcloud = {
          rule = "Host(`192.168.1.100`) && PathPrefix(`/`)";
          service = "nextcloud";
          entryPoints = [ "web" ];
        };
        jellyfin = {
          rule = "Host(`192.168.1.100`) && PathPrefix(`/jellyfin`)";
          service = "jellyfin";
          entryPoints = [ "web" ];
        };
      };
      services = {
        nextcloud.loadBalancer.servers = [{ url = "http://127.0.0.1:8082"; }];
        jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:8096"; }];
      };
    };
  };
};

  # Osnovni alati
  environment.systemPackages = with pkgs; [
    vim
    nano
    wget
    curl
    git
    htop
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
