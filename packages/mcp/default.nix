{
  lib,
  bun2nix,
  formats,
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

      postPatch =
        let
          justfileConfig = (formats.json { }).generate "justfile-config.json" (
            if justfile != null then justfile.config else { }
          );
        in
        ''
          substituteInPlace index.ts \
            --replace-fail '@JUSTFILE_CONFIG@' '${justfileConfig}'
        '';

      passthru.withJustfile = mkMcp;
    };
in
mkMcp null
