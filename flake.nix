{
  description = "Tabry";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          tabry = import ./default.nix pkgs;
          tabryLang = import ./tabry-lang/tabry-lang.nix flake-utils pkgs;
        in {
          packages = {
            # defaults
            tabry = tabry;
            tabryBuild = tabryLang.build;
            tabryBuildBasic = tabryLang.buildBasic;
          };
          apps = {
            tabryc = tabryLang.tabryc;
          };
        }
    );
}