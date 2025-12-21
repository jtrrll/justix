{ inputs, ... }:
{
  perSystem =
    {
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      packages =
        let
          inherit (inputs.nixpkgs-just.legacyPackages.${system}) just;
        in
        rec {
          justfile = pkgs.callPackage ./justfile.nix {
            inherit just;
          };
          justix = pkgs.callPackage ./justix.nix {
            inherit just justfile;
          };
          mcp = pkgs.callPackage ./mcp {
            inherit (inputs'.bun2nix.packages) bun2nix;
          };
        };
    };
}
