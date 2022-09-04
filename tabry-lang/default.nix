flake-utils: {
  yarn2nix,
  yarn2nix-moretea,
  mkYarnPackage,
  nodePackages,
  python3,
  stdenv,
  bundlerEnv,
  ruby,
  lib,
  coreutils,
  nodejs,
  fetchzip,
  xcbuild,
  ...
} @pkgs:
  let tabryRepo = builtins.fetchGit {
    url = "git@github.com:evanbattaglia/tabry.git";
    ref = "master";
    rev = "0f64dc4e78feee0b6f802095d5872b6448b6063f";
  };

  formatJsonFilename = inFile: 
    (builtins.replaceStrings [".tabry"] [""] (builtins.baseNameOf inFile)) + ".json";

  # todo
  compileTabryFile = inFile: stdenv.mkDerivation {
    name = "tabry-compile";
    src = "${tabryRepo}/treesitter";
    buildInputs = [nodejs];
    buildPhase = ''
      # Build the distribution bundle in "dist"
      ./tabry-compile.js ${inFile} $out/${formatJsonFilename inFile}
    '';
  };

  tabryBuild = mkYarnPackage {
    name = "tabry-thing";
    src = "${tabryRepo}/treesitter";
    patches = [./yarn.patch];
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;
    extraBuildInputs = [ python3 xcbuild ];
    pkgConfig.tree-sitter = {
      buildInputs = [ nodePackages.node-gyp python3 xcbuild ];
      postInstall = ''
        ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp --nodedir ${nodejs} configure
        ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp --nodedir ${nodejs} rebuild
      '';
    };
    postBuild = ''
      cd deps/tree-sitter-tabry
      ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp --nodedir ${nodejs} rebuild
      cd ../../
    '';
  };

  tabryc = flake-utils.lib.mkApp {
    drv = tabryBuild;
    name = "tabryc";
    exePath = "/libexec/tree-sitter-tabry/deps/tree-sitter-tabry/tabry-compile.js";
  };

  in {
    inherit tabryc compileTabryFile tabryBuild;
  }
