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
            type = lib.types.either lib.types.path (lib.types.attrsOf lib.types.anything);
          };
        };

        config = lib.mkIf cfg.enable {
          justix.finalPackage =
            let
              name = builtins.baseNameOf config.env.DEVENV_ROOT;
              justix =
                if (lib.isPath cfg.justfile) then
                  cfg.package.withJustfile name cfg.justfile
                else
                  cfg.package.withModules name [ cfg.justfile ];
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
        };
      };
  };
}
