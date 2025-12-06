{
  description = "Build Justfiles with Nix!";

  inputs = {
    devenv = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/devenv";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-just.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    snekcheck = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jtrrll/snekcheck";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./dev_shells
        ./devenv_modules
        ./formatter
        ./packages
      ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
    };
}
