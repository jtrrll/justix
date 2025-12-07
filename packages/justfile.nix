{
  lib,
  just,
  runCommand,
  modules ? [ ],
}:
let
  cfg =
    (lib.evalModules {
      modules = [
        {
          options = {
            name = lib.mkOption {
              default = "justfile";
              description = "Name of the `justfile` derivation";
              type = lib.types.str;
            };

            recipes = lib.mkOption {
              default = { };
              description = "Recipes to include in the `justfile`.";
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    aliases = lib.mkOption {
                      default = [ ];
                      description = "Alternative names for this recipe.";
                      type = lib.types.listOf lib.types.str;
                    };
                    attributes = lib.mkOption {
                      default = { };
                      description = "Annotations that change the behavior of this recipe.";
                      type = lib.types.attrsOf (lib.types.either lib.types.bool lib.types.str);
                    };
                    commands = lib.mkOption {
                      default = "";
                      description = "Commands to execute when running this recipe.";
                      type = lib.types.str;
                    };
                    dependencies = lib.mkOption {
                      default = [ ];
                      description = "Other recipes that will run before this recipe.";
                      type = lib.types.listOf lib.types.str;
                    };
                    parameters = lib.mkOption {
                      default = [ ];
                      description = "Parameters available to this recipe.";
                      type = lib.types.listOf lib.types.str;
                    };
                  };
                }
              );
            };

            extraConfig = lib.mkOption {
              default = "";
              description = "Extra text to prepend to the `justfile`";
              type = lib.types.lines;
            };

            finalContents = lib.mkOption {
              description = "Resulting `justfile` content.";
              readOnly = true;
              type = lib.types.str;
            };
          };

          config.finalContents =
            let
              assertVal =
                f: x:
                assert f x;
                x;
              mkAlias = alias: name: "alias ${alias} := ${name}";
              mkAliases = name: recipe: lib.concatMapStringsSep "\n" (alias: mkAlias alias name) recipe.aliases;
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
                      (assertVal (lib.all (dep: lib.hasAttr (extractRecipeName dep) cfg.recipes)))
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

              extraText = cfg.extraConfig;
              aliasesText = lib.pipe cfg.recipes [
                (lib.mapAttrsToList mkAliases)
                (lib.filter (text: text != ""))
                (lib.sort (x: y: x < y))
                (lib.concatStringsSep "\n")
              ];
              recipesText = lib.pipe cfg.recipes [
                (lib.mapAttrsToList mkRecipe)
                (lib.sort (x: y: x < y))
                (lib.concatStringsSep "\n\n")
              ];
            in
            lib.pipe
              [ extraText aliasesText recipesText ]
              [
                (lib.filter (text: text != ""))
                (lib.concatStringsSep "\n\n")
                (x: lib.optionalString (x != "") "${x}\n")
              ];
        }
      ]
      ++ modules;
    }).config;
in
runCommand cfg.name
  {
    text = cfg.finalContents;
    passAsFile = [ "text" ];
    nativeBuildInputs = [ just ];
    meta.description = "Justfile for ${cfg.name}";
  }
  ''
    mv "$textPath" "$out"

    ${lib.getExe just} --justfile "$out" --fmt --unstable --check
  ''
