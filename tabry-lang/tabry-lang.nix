flake-utils: {
  yarn2nix,
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
  nodejs-14_x,
  ...
} @pkgs:
  let tabryRepo = builtins.fetchGit {
    url = "git@github.com:evanbattaglia/tabry.git";
    ref = "master";
    rev = "0f64dc4e78feee0b6f802095d5872b6448b6063f";
  };

  nodeHeaders = fetchzip {
    name = "node-v${nodejs.version}-headers";
    url = "https://nodejs.org/download/release/v${nodejs.version}/node-v${nodejs.version}-headers.tar.gz";
    sha256 = "sha256-Ntft3gQXrTOVvybMV606+z0LhinldIurDl9yHSHANQc=";
  };

  nodeDependencies = (pkgs.callPackage ./default.nix {pkgs = pkgs;}).nodeDependencies;

  formatJsonFilename = inFile: 
    (builtins.replaceStrings [".tabry"] [""] (builtins.baseNameOf inFile)) + ".json";

  compileTabryFile = inFile: stdenv.mkDerivation {
    name = "tabry-compile";
    src = "${tabryRepo}/treesitter";
    buildInputs = [nodejs];
    buildPhase = ''
      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      export PATH="${nodeDependencies}/bin:$PATH"

      # Build the distribution bundle in "dist"
      ./tabry-compile.js ${inFile} $out/${formatJsonFilename inFile}
    '';
  };

  build = mkYarnPackage {
    name = "tabry-thing";
    src = "${tabryRepo}/treesitter";
    patches = [./yarn.patch];
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;
    pkgConfig.tree-sitter = {
      buildInputs = [ nodePackages.node-gyp python3 ];
      postInstall = ''
        # tried both of these:
        # ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp --nodedir ${nodejs} configure
        # ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp --nodedir ${nodejs} build
        node-gyp --nodedir=${nodeHeaders} --target=v16.16.0 configure
        node-gyp --nodedir=${nodeHeaders} --target=v16.16.0 rebuild
      '';
    };
  };

  buildBasic = stdenv.mkDerivation {
    name = "foo";
    src = "${tabryRepo}/treesitter";
    buildInputs = [nodejs];
    patches = [./packages.patch];
    buildPhase = ''
      # https://github.com/tree-sitter/tree-sitter/releases/download/v0.20.6/tree-sitter-linux-x64.gz
      mkdir $out
      cp -R ./* $out
      npm ci
    '';
  };

  tabrycEnv = stdenv.mkDerivation {
    name = "tabry-compile";
    src = "${tabryRepo}/treesitter";
    # patches = [./packages.patch];
    buildInputs = [nodejs];
    buildPhase = ''
      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
    '';
  };

  tabryc = flake-utils.lib.mkApp {
    drv = tabrycEnv;
    name = "tabryc";
    exePath = "tabry-compile.js";
  };

  in {
    inherit buildBasic;
    compileTabryFile = compileTabryFile;
    tabryc = tabryc;
    build = build;
  }
