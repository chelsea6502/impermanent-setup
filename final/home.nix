{ pkgs, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

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

}
