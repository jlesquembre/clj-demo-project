{
  description = "A flake for clj-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    clj-nix = {
      url = "github:jlesquembre/clj-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            jdkRunner = pkgs.jdk17_headless;
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
                Cmd = "${graalDrv}/bin/${graalDrv.name}";
              };
            };

          clj-kondo =
            let
              version = "v2022.03.09";
              cljDrv = cljpkgs.mkCljBin {
                projectSrc = pkgs.fetchFromGitHub {
                  owner = "clj-kondo";
                  repo = "clj-kondo";
                  rev = version;
                  hash = "sha256-Yjyd48lg1VcF8pZOrEqn5g/jEmSioFRt0ETSJjp0wWU=";
                };
                lock-file = ./extra-pkgs/clj-kondo/deps-lock.json;

                # https://github.com/clj-kondo/clj-kondo/blob/61d1447a56de0610c0c500fc6f6e9d6647f2262c/project.clj#L32
                java-opts = [
                  "-Dclojure.compiler.direct-linking=true"
                  "-Dclojure.spec.skip-macros=true"
                ];
                name = "clj-kondo";
                inherit version;
                main-ns = "clj-kondo.main";
                jdkRunner = pkgs.jdk17_headless;
              };
            in
            cljpkgs.mkGraalBin {
              inherit cljDrv;
            };

        };
      });

}
