{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.justix = {
    justfilePackage =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options = {
          contents = lib.mkOption {
            default = "";
            description = "The contents of the justfile";
            type = lib.types.separatedString "\n\n";
            apply =
              text:
              lib.readFile (
                pkgs.runCommand "${config.name}-justfile-fmt"
                  {
                    inherit text;
                    passAsFile = [ "text" ];
                    nativeBuildInputs = [ pkgs.just ];
                  }
                  ''
                    ${lib.getExe pkgs.just} --justfile "$textPath" --fmt --unstable
                    mv "$textPath" "$out"
                  ''
              );
          };
          name = lib.mkOption {
            description = "An identifier for the justfile";
            type = lib.types.str;
          };
          structuredContents = lib.mkOption {
            description = "A structured JSON representation of the justfile";
            readOnly = true;
            type = lib.types.attrs;
          };
          finalJustfile = lib.mkOption {
            description = "The final justfile package";
            readOnly = true;
            type = lib.types.package;
          };
        };
        config = {
          structuredContents = lib.importJSON (
            pkgs.runCommand "${config.name}-justfile-dump.json"
              {
                text = config.contents;
                passAsFile = [ "text" ];
                nativeBuildInputs = [ pkgs.just ];
                meta.description = "A dump of the ${config.name} justfile";
              }
              ''
                ${lib.getExe pkgs.just} --justfile "$textPath" --dump --dump-format json > "$out"
              ''
          );
          finalJustfile =
            pkgs.runCommand "${config.name}-justfile"
              {
                text = config.contents;
                passAsFile = [ "text" ];
                meta.description = "The ${config.name} justfile";
              }
              ''
                mv "$textPath" "$out"
              '';
        };
      };
    justfileRecipes =
      { config, lib, ... }:
      {
        options.recipes = lib.mkOption {
          default = { };
          description = "Recipes to include in the justfile";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                aliases = lib.mkOption {
                  default = [ ];
                  description = "Alternative names for this recipe";
                  type = lib.types.listOf lib.types.str;
                };
                attributes = lib.mkOption {
                  default = { };
                  description = "Annotations that change the behavior of this recipe";
                  type = lib.types.attrsOf (lib.types.either lib.types.bool lib.types.str);
                };
                commands = lib.mkOption {
                  default = "";
                  description = "Commands to execute when running this recipe";
                  type = lib.types.str;
                };
                dependencies = lib.mkOption {
                  default = [ ];
                  description = "Other recipes that will run before this recipe";
                  type = lib.types.listOf lib.types.str;
                };
                parameters = lib.mkOption {
                  default = [ ];
                  description = "Parameters available to this recipe";
                  type = lib.types.listOf lib.types.str;
                };
              };
            }
          );
        };
        config.contents =
          let
            assertVal =
              f: x:
              assert f x;
              x;
            aliasesText =
              let
                mkAlias = alias: name: "alias ${alias} := ${name}";
                mkAliases = name: recipe: lib.concatMapStringsSep "\n" (alias: mkAlias alias name) recipe.aliases;
              in
              lib.pipe config.recipes [
                (lib.mapAttrsToList mkAliases)
                (lib.filter (text: text != ""))
                (lib.sort (x: y: x < y))
                (lib.concatStringsSep "\n")
              ];
            recipesText =
              let
                mkRecipe =
                  name: recipe:
                  let
                    attributes = lib.pipe recipe.attributes [
                      (assertVal lib.isAttrs)
                      (lib.mapAttrsToList (
                        name: value:
                        if lib.isBool value then lib.optionalString value "[${name}]" else "[${name}('${value}')]"
                      ))
                      (lib.filter (str: str != ""))
                      (lib.sort (x: y: x < y))
                      (lib.concatStringsSep "\n")
                      (assertVal lib.isString)
                    ];
                    commands = lib.pipe recipe.commands [
                      (assertVal lib.isString)
                      (lib.splitString "\n")
                      (lib.filter (str: str != ""))
                      (lib.concatMapStringsSep "\n" (line: "    ${line}"))
                      (assertVal lib.isString)
                    ];
                    dependencies =
                      let
                        extractRecipeName =
                          dep:
                          let
                            withoutParens =
                              if lib.hasPrefix "(" dep then lib.removePrefix "(" (lib.removeSuffix ")" dep) else dep;
                          in
                          lib.head (lib.splitString " " withoutParens);
                      in
                      lib.pipe recipe.dependencies [
                        (assertVal lib.isList)
                        (assertVal (lib.all lib.isString))
                        (assertVal (lib.all (dep: lib.hasAttr (extractRecipeName dep) config.recipes)))
                        (lib.concatMapStrings (dep: " ${dep}"))
                        (assertVal lib.isString)
                      ];
                    parameters = lib.pipe recipe.parameters [
                      (assertVal lib.isList)
                      (assertVal (lib.all lib.isString))
                      (lib.concatMapStrings (param: " ${param}"))
                      (assertVal lib.isString)
                    ];
                  in
                  lib.pipe
                    [ attributes "${name}${parameters}:${dependencies}" commands ]
                    [
                      (lib.filter (text: text != ""))
                      (lib.concatStringsSep "\n")
                    ];
              in
              lib.pipe config.recipes [
                (lib.mapAttrsToList mkRecipe)
                (lib.sort (x: y: x < y))
                (lib.concatStringsSep "\n\n")
              ];
          in
          lib.pipe
            [ aliasesText recipesText ]
            [
              (lib.filter (text: text != ""))
              (lib.concatStringsSep "\n\n")
              (x: lib.optionalString (x != "") "${x}\n")
            ];
      };
  };
}
