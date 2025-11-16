{
  description = "AAAAAAAAAAAAAAAAAAAAAAA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            nodejs_24
            pnpm
            bazelisk
          ];
        };

        packages.baseImage = import ./nix/image.nix { inherit pkgs; };
      });
}

