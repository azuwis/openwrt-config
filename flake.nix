{
  inputs.nixpkgs.url = "flake:nixpkgs";
  inputs.flake-utils.url = "flake:flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = with pkgs; [
          python3
          rsync
          signify
          wget
        ];
      };
    });
}
