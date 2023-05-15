# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs,... }: {
  # Just copied from https://github.com/nix-community/NixOS-WSL/blob/main/configuration.nix
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = true;

    # Enable native Docker support
    docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

 # nixpkgs.overlays = [
 #   (import inputs.emacs-overlay)
 #   (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
 # ];

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # nix options for derivations to persist garbage collection
      keep-outputs = true;
      keep-derivations = true;
    };
  };

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
      package = pkgs.emacs;
    };
  };

  # Set your hostname
  networking.hostName = "luigi";

  environment = with pkgs; { 
    systemPackages = [
      # Appearance
      gsettings-desktop-schemas
      arc-theme
      oh-my-zsh
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
    shellAliases = {
      emacst = "emacsclient --alternate-editor=\"\" -c -tty";
      emacs-reload = "systemctl --user restart emacs";
    };
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
  
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
