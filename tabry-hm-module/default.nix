{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.tabry;

  tabry = import ../default.nix pkgs;

  mkInitFish = commandName: ''
    tabry_completion_init ${commandName}
  '';

in {

  options.programs.tabry = {
    enable = mkEnableOption "tabry, a tab completion library";
    enableFishIntegration = mkEnableOption "enables fish completions";
    tabryFiles = mkOption {
      type = with types; attrsOf (listOf path);
      default = { };
      description = ''
        *.tabry files to be compiled to completion json
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [tabry];

    # for each file, compile it to json
    # then add the dir to $TABRY_IMPORTS_PATH

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      set -x TABRY_IMPORTS_PATH "$TABRY_IMPORTS_PATH ${builtins.concatStringsSep " " cfg.tabryFiles}"
      source ${tabry}/sh/fish/tabry_fish.fish
      ${map mkInitFish cfg.tabryFiles}
    '';
  };
}