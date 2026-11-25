{
  description = "Eren Can Ucar's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      git-hooks,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      theme = import ./theme { inherit (nixpkgs) lib; };

      hooks = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = import ./checks.nix { inherit pkgs; };
      };

      mkHost =
        host:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit unstable theme; };
          modules = [
            ./hosts/${host}
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit unstable theme; };
                users.can = import ./home/can.nix;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.b850e-desktop = mkHost "b850e-desktop";

      checks.${system}.hooks = hooks;

      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        inherit (hooks) shellHook;
        packages = hooks.enabledPackages;
      };
    };
}
