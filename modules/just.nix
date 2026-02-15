{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.justix.justPackage =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = {
        just = lib.mkPackageOption pkgs "just" { };
        finalJust = lib.mkOption {
          description = "The final just package";
          readOnly = true;
          type = lib.types.package;
        };
      };
      config.finalJust = pkgs.symlinkJoin {
        name = "${config.name}-just";
        paths = [ config.just ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/just \
            --add-flags "--justfile ${config.finalJustfile}" \
            --run 'set -- --working-directory "$(pwd)" "$@"'
        '';
      };
    };
}
