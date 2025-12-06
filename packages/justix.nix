{
  just,
  justfile,
  lib,
  makeBinaryWrapper,
  symlinkJoin,
}:
let
  makeJustfile = modules: justfile.override { inherit just modules; };
  makeJust =
    {
      name ? null,
      justfile ? null,
    }:
    symlinkJoin {
      inherit (just) version;
      pname = if name != null then "${name}-justix" else "justix";
      meta.mainProgram = "just";

      paths = [ just ];
      nativeBuildInputs = [ makeBinaryWrapper ];
      postBuild = ''
        wrapProgram $out/bin/just \
          --add-flags "--justfile ${if justfile != null then justfile else makeJustfile [ ]}"
      '';

      passthru = lib.optionalAttrs (justfile == null) {
        withJustfile = name: justfile: makeJust { inherit name justfile; };
        withModules =
          name: modules:
          makeJust {
            inherit name;
            justfile = makeJustfile modules;
          };
      };
    };
in
makeJust { }
