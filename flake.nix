{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = { ... } @ inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    perSystem = { self', system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      lib = pkgs.lib;

      rootCheck = "test -e ./flake.nix || (echo 'Run from root of repository' ; exit 1)";
      arduino-sketch = "nimpad";
      arduino-config = "--config-file ./arduino-cli.yaml";
      arduino-fqbn = "--fqbn arduino:avr:micro";
      arduino-port = "--port /dev/serial/by-id/usb-Arduino_LLC_Arduino_Micro-if00";
    in
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nim nimlsp
            nim_lk jq
            arduino-cli
          ];
          shellHook = ''
            set -e
            ${rootCheck}
            nix run .#setup
            alias arduino-cli="arduino-cli ${arduino-config}"
            alias editor="lite-xl $PWD &"
            alias nr="nix run"
            alias nimpad="nix run .#default -- -l=d -p=/dev/serial/by-id/usb-Arduino_LLC_Arduino_Micro-if00"
          '';
        };
      };
      packages = {
        default = self'.packages.nimpad;
        nimpad = pkgs.callPackage ./package.nix { };
        setup = pkgs.writeShellApplication {
          name = "setup";
          runtimeInputs = with pkgs; [ nim_lk jq nimble ];
          text = ''
            ${rootCheck}
            echo "Updating Nim lock..."
            nim_lk | jq --sort-keys > lock.json
            echo "Installing nimble packages..."
            nimble -l --nimbleDir:.nimble install -d > /dev/null
          '';
        };
        compile = pkgs.writeShellApplication {
          name = "compile";
          runtimeInputs = with pkgs; [ arduino-cli ];
          text = ''
            ${rootCheck}
            arduino-cli compile ${arduino-sketch} ${arduino-config} ${arduino-fqbn}
          '';
        };
        upload = pkgs.writeShellApplication {
          name = "upload";
          runtimeInputs = with pkgs; [ arduino-cli ];
          text = ''
            ${rootCheck}
            ${lib.getExe self'.packages.build};
            arduino-cli upload ${arduino-sketch} ${arduino-config} ${arduino-fqbn} ${arduino-port}
          '';
        };
      };
    };
  };
}

