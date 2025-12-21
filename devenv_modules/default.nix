{ getSystem, ... }:
{
  flake.devenvModules = {
    default =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.justix;
      in
      {
        options.justix = {
          enable = lib.mkEnableOption "justix";
          mcpServer.enable = lib.mkEnableOption "a justfile MCP server";

          package = lib.mkOption {
            type = lib.types.package;
            default = (getSystem pkgs.stdenv.hostPlatform.system).packages.justix;
            description = "The base justix package.";
          };

          finalPackage = lib.mkOption {
            description = "The resulting justix package.";
            readOnly = true;
            type = lib.types.package;
          };

          justfile = lib.mkOption {
            default = { };
            description = "The justfile to use";
            type = lib.types.attrsOf lib.types.anything;
          };
        };

        config = lib.mkIf cfg.enable {
          justix.finalPackage =
            let
              name = builtins.baseNameOf config.env.DEVENV_ROOT;
              justix = cfg.package.withModules name [ cfg.justfile ];
            in
            pkgs.symlinkJoin {
              name = "${name}-justix";
              paths = [ justix ];
              nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
              postBuild = ''
                wrapProgram $out/bin/just \
                  --add-flags "--working-directory ${config.env.DEVENV_ROOT}"
              '';
            };

          packages = [ cfg.finalPackage ];

          claude.code.mcpServers = lib.mkIf cfg.mcpServer.enable {
            justix-mcp = {
              type = "stdio";
              command =
                let
                  justfilePkg = (getSystem pkgs.stdenv.hostPlatform.system).packages.justfile;
                  mcpPkg = (getSystem pkgs.stdenv.hostPlatform.system).packages.mcp;
                in
                lib.getExe (mcpPkg.withJustfile (justfilePkg.withModules [ cfg.justfile ]));
            };
          };
        };
      };
  };
}
