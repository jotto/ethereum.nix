{
  description = "A reproducible Nix package set for Ethereum clients and utilities";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # packages
    nixpkgs.url = "github:nixos/nixpkgs/22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";

    foundry-nix = {
      url = "github:shazow/foundry.nix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = "github:srid/flake-root";
    mission-control.url = "github:Platonic-Systems/mission-control";

    # utils
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (final: _: import ./nix/lib final);
    #    lib = import ./nix/lib {inherit (nixpkgs) lib;} // nixpkgs.lib;
    inherit (builtins) filter match;
  in
    (flake-parts.lib.evalFlakeModule
      {
        inherit inputs;
        specialArgs = {
          inherit lib; # make custom lib available to parent functions
        };
      }
      rec {
        imports = [
          ({inputs', ...}: {
            # make custom lib available to all `perSystem` functions
            _module.args.lib = lib;
          })
          ./nix
          ./packages
          ./modules
          ./mkdocs.nix
          inputs.hercules-ci-effects.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        herculesCI.ciSystems = filter (system: (match ".*-darwin" system) == null) systems;
      })
    .config
    .flake;
}
