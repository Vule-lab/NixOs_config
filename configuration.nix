# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
console.keyMap = "croat";
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "yes";
services.openssh.settings.PasswordAuthentication = true;
networking.firewall.allowedTCPPorts = [ 22  80  443  8080  8082 ];

networking.interfaces.enp0s3.useDHCP = false;
networking.interfaces.enp0s3.ipv4.addresses = [{
  address = "192.168.1.100";
  prefixLength = 24;
}];

networking.defaultGateway = "192.168.1.1";
networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

services.jellyfin = {
  enable = true;          # Aktivira Jellyfin servis
  openFirewall = true;    # Otvara portove (HTTP/HTTPS) na vatrozidu

};

disabledModules = [ "services/web-servers/nginx.nix" ];

services.nextcloud = {
  enable = true;
  hostName = "192.168.1.100";
  configureRedis = true;  # Za bolje performanse
  https = false;          # HTTPS će se dodati kasnije kroz Traefik
  database.createLocally = true;
  config = {
	adminuser = "admin";
  	adminpassFile = "/etc/nixos/nextcloud-admin-pass"; # Datoteka s lozinkom
	dbtype = "pgsql";
       };
};

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


services.redis.servers."".enable = true;

services.traefik = {
  enable = true;
  staticConfigOptions = {
    entryPoints = {
      web = {
        address = ":80";
      };
      traefik = {
        address = ":8080";
      };
    };
    providers = {
      file = {
        filename = "/etc/traefik/routes.toml";
        watch = true;
      };
    };
    api = {
      dashboard = true;
      insecure = true;  # privremeno, za lokalni test
    };
  };
};


  
environment.etc."traefik/routes.toml".text = ''
[http.routers.nextcloud]
rule = "PathPrefix(`/nextcloud`)"
service = "nextcloud"
entryPoints = ["web"]

[http.services.nextcloud.loadBalancer]
[[http.services.nextcloud.loadBalancer.servers]]
url = "http://127.0.0.1:8082"

[http.routers.jellyfin]
rule = "PathPrefix(`/jellyfin`)"
service = "jellyfin"
entryPoints = ["web"]

[http.services.jellyfin.loadBalancer]
[[http.services.jellyfin.loadBalancer.servers]]
url = "http://localhost:8096"
'';




  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];
environment.systemPackages = with pkgs; [
    vim
    nano
    wget
    curl
    git
    htop

  ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

