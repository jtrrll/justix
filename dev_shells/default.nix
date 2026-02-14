{ inputs, self, ... }:
{
  imports = [ inputs.devenv.flakeModule ];
  perSystem =
    {
      inputs',
      lib,
      ...
    }:
    {
      devenv = {
        modules = [
          {
            containers = lib.mkForce { }; # Workaround to remove containers from flake checks.
          }
          self.devenvModules.default
        ];
        shells.default =
          { lib, pkgs, ... }:
          {
            enterShell = lib.getExe (
              pkgs.writeShellApplication rec {
                meta.mainProgram = name;
                name = "splashScreen";
                runtimeInputs = [
                  pkgs.lolcat
                  pkgs.uutils-coreutils-noprefix
                ];
                text = ''
                  printf "     __                __   __
                      |__|__ __  _______/  |_|__|__  ___
                      |  |  |  \/  ___/\   __\  \  \/  /
                      |  |  |  /\___ \  |  | |  |>    <
                  /\__|  |____//____  > |__| |__/__/\_ \\
                  \______|          \/                \/\n" | lolcat
                  printf "\033[0;1;36mDEVSHELL ACTIVATED\033[0m\n"
                '';
              }
            );

            claude.code.enable = true;

            justix = {
              enable = true;
              justfile.config = {
                recipes = {
                  default = {
                    attributes = {
                      default = true;
                      doc = "Lists available recipes";
                      private = true;
                    };
                    commands = "@just --list";
                  };
                  fmt = {
                    attributes.doc = "Formats and lints files";
                    commands = ''
                      @files=(); \
                      for path in {{ paths }}; do \
                        if [ -f "$path" ]; then \
                          files+=("$path"); \
                        elif [ -d "$path" ]; then \
                          while IFS= read -r -d "" file; do \
                            files+=("$file"); \
                          done < <(find "$path" ! -path '*/.*' ! -path '*/node_modules/*' -type f -print0); \
                        fi; \
                      done; \
                      [ ''${#files[@]} -gt 0 ] && ${lib.getExe inputs'.snekcheck.packages.default} --fix "''${files[@]}"
                      @nix fmt -- {{ paths }} 2>&1
                    '';
                    parameters = [ "*paths='.'" ];
                  };
                };
              };
            };

            languages = {
              javascript = {
                bun.enable = true;
                enable = true;
              };
              nix = {
                enable = true;
                lsp.package = pkgs.nixd;
              };
              typescript.enable = true;
            };

            packages = [
              inputs'.bun2nix.packages.bun2nix
              pkgs.vtsls
            ];

            git-hooks = {
              default_stages = [ "pre-push" ];
              hooks = {
                actionlint.enable = true;
                check-added-large-files = {
                  enable = true;
                  stages = [ "pre-commit" ];
                };
                check-json.enable = true;
                check-yaml.enable = true;
                deadnix.enable = true;
                detect-private-keys = {
                  enable = true;
                  stages = [ "pre-commit" ];
                };
                end-of-file-fixer.enable = true;
                flake-checker.enable = true;
                markdownlint.enable = true;
                mixed-line-endings.enable = true;
                nil.enable = true;
                no-commit-to-branch = {
                  enable = true;
                  stages = [ "pre-commit" ];
                };
                ripsecrets = {
                  enable = true;
                  stages = [ "pre-commit" ];
                };
                statix.enable = true;
              };
            };
          };
      };
    };
}
