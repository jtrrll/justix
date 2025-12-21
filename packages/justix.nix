{
  just,
  justfile,
  lib,
  makeBinaryWrapper,
  symlinkJoin,
}:
let
  mkJustfile = justfile.withModules;
  mkJust =
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
          --add-flags "--justfile ${if justfile != null then justfile else mkJustfile [ ]}"
      '';

      passthru = lib.optionalAttrs (justfile == null) {
        withModules =
          name: modules:
          mkJust {
            inherit name;
            justfile = mkJustfile modules;
          };
      };
    };
in
mkJust { }
