{ inputs, pkgs, config, modulesPath, ... }:

let
  nixos-wsl = import ./default.nix;
in
{
  imports = [
    nixos-wsl.nixosModules.wsl
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = true;
    nativeSystemd = true;

    # Enable native Docker support
    docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;

  };

  nixpkgs.overlays = [
    (import inputs.emacs-overlay)
    (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
  ];

  
  services = {
    # Appearance
    xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      gtk-theme=Arc-Dark
    '';

    # Text editors
    # emacs.package = pkgs.emacsPgtk;
    emacs = {
      defaultEditor = true;
      enable = true; # Enable emacs as service
      package = pkgs.emacsPgtk;
    };
  };

  # Set your hostname
  networking.hostName = "luigi";

  environment = with pkgs; { 
    systemPackages = [
      # Appearance
      gsettings-desktop-schemas
      arc-theme
      zsh
      zsh-powerlevel10k

      # Tools
      direnv
      nix-direnv
      git
      gnumake
      fd
      fzf
      ripgrep
      wget
      wl-clipboard

      # Core Languages
      gcc
      (python310.withPackages (ps: with ps; [
        pip
        jupyter
      ]))
      texlive.combined.scheme-full
    ];

    pathsToLink = [
      "/share/nix-direnv"
    ];

    # Appearance
    variables.XDG_DATA_DIRS = lib.mkForce 
      "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:$XDG_DATA_DIRS";
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Iosevka Nerd Font" ];
        serif = [ "Iosevka Etoile" ];
        sansSerif = [ "Iosevka Aile" ];
      };
    };
    fonts = with pkgs; [
      (iosevka-bin.override { variant = "aile"; })
      (iosevka-bin.override { variant = "etoile"; })
      (nerdfonts.override { fonts = [ "Iosevka" ]; })
    ];
  };

  # Configure zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "fzf" ];
    };
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    shellInit = ''
      export COLORTERM=truecolor
      eval "$(direnv hook zsh)"
    '';
  };

  users = {
    defaultUserShell = pkgs.zsh;
    extraGroups.docker.members = [ "nixos" ];
  };
  
  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "22.11";
}
