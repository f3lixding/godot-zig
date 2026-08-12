{
  description = "Zig binding for godot 4";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      zig-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };
        zig = pkgs.zigpkgs."0.16.0";
        zls = pkgs.zls_0_16;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "godot-zig";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ zig.hook ];

          installPhase = ''
            mkdir -p $out/lib
            cp zig-out/lib/* $out/lib
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            zig
            zls
          ];
        };
      }
    );
}
