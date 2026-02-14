{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      packages.justfile = pkgs.callPackage ./justfile.nix {
        inherit (inputs.nixpkgs-just.legacyPackages.${system}) just;
      };
    };
}
