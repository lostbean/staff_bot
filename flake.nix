{
  description = "Staff bot flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        unstable-packages = final: _prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            unstable-packages
          ];
        };

        isDarwin = builtins.match ".*-darwin" pkgs.stdenv.hostPlatform.system != null;

        shell = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              unstable.elixir
              unstable.elixir-ls
              unstable.erlang
              rebar3
              nodejs_22
              openssl
              flyctl
            ]
            ++ (
              if isDarwin then
                [
                  darwin.apple_sdk.frameworks.Security
                  darwin.apple_sdk.frameworks.Foundation
                  darwin.apple_sdk.frameworks.CoreML
                ]
              else
                [ ]
            );
          shellHook = ''
            echo "👷"
          '';
        };

      in
      {
        devShells.default = shell;
      }
    );
}
