{
  description = "A flake for clj-nix";

  nixConfig.substituters = [ "https://clj-nix.cachix.org" ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    clj-nix.url = "github:jlesquembre/clj-nix";
  };
  outputs = { self, nixpkgs, flake-utils, clj-nix }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        cljpkgs = clj-nix.packages."${system}";
      in

      {
        packages = {

          clj-tuto = cljpkgs.mkCljBin {
            projectSrc = ./.;
            name = "me.lafuente/clj-tuto";
            version = "1.0";
            main-ns = "demo.core";
            # jdkRunner = pkgs.jdk17_headless;

            # buildCommand example
            # buildCommand = "clj -T:build uber";

            # mkDerivation attributes
            doCheck = true;
            checkPhase = "clj -M:test";
          };

          clj-lib = cljpkgs.mkCljLib {
            projectSrc = ./.;
            name = "me.lafuente/clj-tuto";
            version = "1.0";
            # buildCommand = "clj -T:build jar";
          };

          clj-cache = cljpkgs.mk-deps-cache {
            lockfile = ./deps-lock.json;
          };

          jdk-tuto = cljpkgs.customJdk {
            cljDrv = self.packages."${system}".clj-tuto;
            locales = "en,es";
          };

          graal-tuto = cljpkgs.mkGraalBin {
            cljDrv = self.packages."${system}".clj-tuto;
          };

          clj-container =
            pkgs.dockerTools.buildLayeredImage {
              name = "clj-nix";
              tag = "latest";
              config = {
                Cmd = clj-nix.lib.mkCljCli { jdkDrv = self.packages."${system}".jdk-tuto; };
              };
            };

          graal-container =
            let
              graalDrv = self.packages."${system}".graal-tuto;
            in
            pkgs.dockerTools.buildLayeredImage {
              name = "clj-graal-nix";
              tag = "latest";
              config = {
                Cmd = "${graalDrv}/bin/${graalDrv.pname}";
              };
            };

          babashka = cljpkgs.mkBabashka { withFeatures = [ "jdbc" "sqlite" ]; };
        };
      });

}
