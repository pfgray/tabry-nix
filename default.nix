{ stdenv, bundlerEnv, ruby, lib, coreutils, ... }:
let
  # TODO: would be easier to put this directly into the tabry repo
  gems = bundlerEnv {
    name = "tabry-env";
    inherit ruby;
    gemdir  = ./.;
  };
in stdenv.mkDerivation {
  name = "tabry";
  # src = ../tabry;
  src = builtins.fetchGit {
    url = "git@github.com:evanbattaglia/tabry.git";
    ref = "master";
    rev = "0f64dc4e78feee0b6f802095d5872b6448b6063f";
  };
  patches = [./bin.patch];
  buildInputs = [gems gems.wrappedRuby];
  installPhase = ''
    mkdir -p $out
    cp -R ./* $out
  '';
}