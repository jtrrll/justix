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
        {
          justfile = pkgs.callPackage ./justfile.nix {
            inherit just;
          };
          mcp = pkgs.callPackage ./mcp {
            inherit (inputs'.bun2nix.packages) bun2nix;
          };
        };
    };
}
