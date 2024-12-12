{ pkgs, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  home.homeDirectory = "/home/chelsea";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
  programs.qutebrowser.enable = true;
  programs.foot.enable = true;
  programs.btop.enable = true;
  programs.ranger.enable = true;
  programs.feh.enable = true;

  programs.git = {
    enable = true;
    userName = "Chelsea Wilkinson";
    userEmail = "mail@chelseawilkinson.me";
  };

  programs.qutebrowser.settings = {
    tabs.show = "multiple";
    statusbar.show = "in-mode";
    content.javascript.clipboard = "access-paste";
  };

  programs.foot.settings = { main.pad = "24x24 center"; };

  stylix.autoEnable = true;


  home.persistence."/persist/home" = {
    directories = [
      #"Downloads"
      #"Music"
      #"Pictures"
      #"Documents"
      #"Videos"
      #"VirtualBox VMs"
      ".gnupg"
      ".ssh"
      ".nixops"
      ".local/share/keyrings"
      ".local/share/direnv"
      #{
      #  directory = ".local/share/Steam";
      #  method = "symlink";
      #}
    ];
    files = [
      ".screenrc"
    ];
    allowOther = true;
  };
}
