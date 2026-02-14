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

          just.package = lib.mkPackageOption pkgs "just" { };

          justfile = {
            config = lib.mkOption {
              default = { };
              description = "The justfile configuration.";
              type = lib.types.attrsOf lib.types.anything;
            };
            package = lib.mkOption {
              type = lib.types.package;
              default = (getSystem pkgs.stdenv.hostPlatform.system).packages.justfile;
              description = "The base justfile package.";
            };
            finalPackage = lib.mkOption {
              description = "The resulting justfile package.";
              readOnly = true;
              type = lib.types.package;
            };
          };
        };

        config = lib.mkMerge [
          (lib.mkIf cfg.enable {
            justix.justfile.finalPackage = cfg.justfile.package.withModules [
              { name = lib.mkDefault (builtins.baseNameOf config.devenv.root); }
              cfg.justfile.config
            ];

            packages = [ cfg.just.package ];

            enterShell = ''
              ln --force --symbolic ${cfg.justfile.finalPackage} ${config.devenv.root}/.justfile
            '';
          })

          (lib.mkIf (!cfg.enable) {
            enterShell = ''
              if [[ -L ${config.devenv.root}/.justfile ]]; then
                justfile_path=$(readlink ${config.devenv.root}/.justfile)
                if ${pkgs.nix}/bin/nix-store --quiet --verify-path "$justfile_path" 2>/dev/null; then
                  rm ${config.devenv.root}/.justfile
                fi
              fi
            '';
          })
        ];
      };
  };
}
