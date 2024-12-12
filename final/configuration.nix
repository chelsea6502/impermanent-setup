{ pkgs, lib, inputs, ... }:
let
  patchedDwl = (pkgs.dwl.overrideAttrs (old: rec {
    buildInputs = old.buildInputs ++ [ pkgs.fcft pkgs.pixman pkgs.libdrm ];
    preConfigure = "cp ${./dwl/config.h} config.h";
    patches = [
      ./dwl/patches/bar.patch
      ./dwl/patches/autostart.patch
      ./dwl/patches/unclutter.patch
      #./dwl/patches/smartborders.patch
      ./dwl/patches/gaps.patch
    ];
  }));
  patchedSlstatus = (pkgs.slstatus.overrideAttrs
    (old: rec { preConfigure = "cp ${./dwl/slstatus/config.h} config.h"; }));

in
{

  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  nix.settings.max-jobs = 8;
  boot.kernelPackages = pkgs.linuxPackages-libre;
  boot.kernelParams = [ "video=3840x2160@60" ];
  hardware.display.outputs.DP-2.mode = "3840x2160@60";

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    find = "sudo -E -s ranger";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    EC = "sudo -E -s nvim /etc/nixos/configuration.nix && switch";
    ECC = "sudo -E -s nvim /etc/nixos/configuration.nix && nix-full";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    En = "sudo -E -s nvim /etc/nixos/nixvim.nix";
    Ew = "sudo -E -s nvim /etc/nixos/dwl/config.h";
    EW = "sudo -E -s nvim /etc/nixos/dwl/config.h && switch";
    saveconf = "sudo cp -R /etc/nixos/*.nix ~/nixos-config/";
    loadconf = "sudo cp -R /etc/nixos/* ~/nixos-config/";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "sudo nix-collect-garbage && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = 1;
    EDITOR = "nvim";
  };

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = false;
  networking.firewall.enable = true;

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.getty.autologinUser = "chelsea";
  services.openssh.enable = true;

  # sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  programs.nixvim = ./nixvim.nix;
  home-manager.backupFileExtension = "backup";

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "chelsea" = import ./home.nix;
    };
  };

  security.polkit.enable = true;
  stylix.enable = true;
  stylix.image = ./dwl/wallpaper.png;

  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

  stylix.fonts = {
    serif = {
      package = pkgs.open-sans;
      name = "Open Sans";
    };
    sansSerif = {
      package = pkgs.open-sans;
      name = "Open Sans";
    };
    monospace = {
      package = pkgs.fira-code-nerdfont;
      name = "Fira Code Nerdfont";
    };
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };


  environment.systemPackages = with pkgs; [
    git
    pulseaudio
    swayidle
    wlr-randr
    swaybg
  ];
  users.users.chelsea = {
    isNormalUser = true;
    description = "chelsea";
    initialPassword = "blah";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ qutebrowser wmenu patchedDwl patchedSlstatus ];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${patchedSlstatus}/bin/slstatus -s | ${patchedDwl}/bin/dwl";
        user = "chelsea";
      };
      default_session = initial_session;
    };
  };

  system.stateVersion = "24.11";

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      #{ directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      # { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
  };

  programs.fuse.userAllowOther = true;

}
