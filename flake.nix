{
  description = "A flake wrapper around Google-Closure-Compiler-ACOCR";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs =
          nixpkgs.legacyPackages.${system};

        version =
          "1.0.2";

        src =
          pkgs.fetchFromGitHub {
            repo = "Google-Closure-Compiler-ACOCR";
            owner = "sd-yip";
            rev = version;
            hash = "sha256-HDV/lYiW+g3yzkt6HYo2iAlW3isyUkkXjWNrCNjL6iI=";
          };

        outputScript =
          pkgs.writeShellApplication {
            name =
              "Google-Closure-Compiler-ACOCR-cli-js-patched";

            runtimeInputs =
              [ pkgs.closurecompiler pkgs.jdk17 ];

            text =
              let
                compilerDir =
                  builtins.readDir "${pkgs.closurecompiler}/share/java/";

                compilerJar =
                  builtins.head (builtins.attrNames compilerDir);
              in
              ''
              java -cp ${classes}/classes:${pkgs.closurecompiler}/share/java/${compilerJar} io.lemm.acocr.AcocrCommandLineRunner "$@"
              '';
          };

        classes =
          pkgs.stdenv.mkDerivation {
            inherit version src;

            pname =
              "Google-Closure-Compiler-ACOCR-classes";

            nativeBuildInputs =
                with pkgs; [ closurecompiler jdk17 makeWrapper ];

            buildPhase =
                ''
                  javac -d classes -cp ${pkgs.closurecompiler}/share/java/closure-compiler-*.jar AcocrCommandLineRunner.java
                '';

            installPhase =
              ''
                mkdir -p $out
                cp -r classes $out
              '';
          };
      in
        {
          packages = {
            default = pkgs.stdenv.mkDerivation {
              pname = "closure-compiler-acocr";
              version = "0.1.0";
              src = ./.;
              installPhase =
                ''
                  mkdir -p $out/bin
                  cp ${outputScript}/bin/* $out/bin/closure-compiler-acocr
                '';
            };
          };

          devShell = pkgs.mkShell {
            inputsFrom = [ ]; # Include build inputs from packages in
            # this list
            packages = [ ]; # Extra packages to go in the shell
          };
        }
    );

}
