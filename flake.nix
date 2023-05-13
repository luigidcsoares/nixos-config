{
  description = "NixOS (WSL) Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
  };

  outputs = { nixpkgs, ...}@inputs: {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        # Pass flake inputs to our config
        specialArgs = { inherit inputs; }; 
        modules = [ 
          # NixOS on WSL module
          inputs.nixos-wsl.nixosModules.wsl
          # Generated (nixos-generate-config) hardware configuration
          ./hardware-configuration.nix
          # Our main nixos configuration file
          ./configuration.nix  
        ];
      };
    };
  };
}
