{
  description = "Basic flake for bemenu";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        bemenu = pkgs.bemenu;
        default = self.packages.${system}.bemenu;
      };

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          bemenu
          sway
        ];

        shellHook = ''
          export PATH=${pkgs.bemenu}/bin:$PATH
          export BEMENU_BACKEND=wayland
        '';
      };
    });
}
