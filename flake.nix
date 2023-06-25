{
  description = "A flake for clj-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
    clj-nix.url = "github:jlesquembre/clj-nix";
  };
  outputs = { self, nixpkgs, flake-utils, devshell, clj-nix }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
            clj-nix.overlays.default
          ];
        };
      in

      {
        packages = {

          clj-tuto = pkgs.mkCljBin {
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

          clj-lib = pkgs.mkCljLib {
            projectSrc = ./.;
            name = "me.lafuente/clj-tuto";
            version = "1.0";
            # buildCommand = "clj -T:build jar";
          };

          clj-cache = pkgs.mk-deps-cache {
            lockfile = ./deps-lock.json;
          };

          jdk-tuto = pkgs.customJdk {
            cljDrv = self.packages."${system}".clj-tuto;
            locales = "en,es";
          };

          graal-tuto = pkgs.mkGraalBin {
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

          babashka = pkgs.mkBabashka { withFeatures = [ "jdbc" "sqlite" ]; };
        };

        devShells.default =
          pkgs.devshell.mkShell {
            packages = [
              pkgs.clojure
            ];
            commands = [
              {
                name = "update-deps";
                help = "Update deps-lock.json";
                command =
                  ''
                    nix run github:jlesquembre/clj-nix#deps-lock
                  '';
              }
            ]
            ++ pkgs.bbTasksFromFile {
              file = ./tasks.clj;
              bb = self.packages."${system}".babashka;
            };
            # if we want to use the default nixpkgs babashka version:
            # ++ pkgs.bbTasksFromFile ./tasks.clj
          };

      });

}
