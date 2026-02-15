{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.devenv.justix =
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
        config = lib.mkOption {
          default = { };
          description = "The justfile configuration.";
          type = lib.types.submoduleWith {
            modules = (lib.attrValues inputs.self.modules.justix) ++ [
              { name = lib.mkDefault (builtins.baseNameOf config.devenv.root); }
              { _module.args = { inherit pkgs; }; }
            ];
          };
        };
      };
      config.packages = lib.mkIf cfg.enable [ cfg.config.finalJust ];
    };
}
