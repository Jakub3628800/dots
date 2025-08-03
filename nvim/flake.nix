{
  description = "Neovim installation flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = pkgs.neovim-unwrapped;
          neovim = pkgs.neovim-unwrapped;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            neovim-unwrapped
          ];
        };
      });
}
