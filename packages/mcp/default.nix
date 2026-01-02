{
  bun2nix,
  just,
  lib,
}:
let
  mkMcp =
    justfile:
    bun2nix.mkDerivation {
      packageJson = ./package.json;
      meta = {
        description = "MCP server that exposes justfile commands as AI tools";
        homepage = "https://github.com/jtrrll/justix";
        license = lib.licenses.mit;
        mainProgram = "justix-mcp";
      };

      src = ./.;

      bunDeps = bun2nix.fetchBunDeps {
        bunNix = ./bun.nix;
      };

      module = "index.ts";

      postPatch = ''
        substituteInPlace index.ts \
          --replace-fail '@JUST_BINARY@' '${lib.getExe just}' \
          --replace-fail '@JUSTFILE@' '${justfile}'
      '';

      bunCompileToBytecode = false;

      passthru.withJustfile = mkMcp;
    };
in
mkMcp null
