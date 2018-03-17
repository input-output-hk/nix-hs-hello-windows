let
  pkgsPath = import ./fetchNixpkgs.nix {
    rev = "c8f682e7cc3d75066beab1ffa8696c45ec4dab3f";
    sha256 = "1v1jza5j3y9x067gl9lpn1g4w90swpjgydn3n1wnkxwndrn52z9h";
    sha256unpacked = "0dv29399nf6b5qhl16hkcaz71kwjn3mv2m2ydc8p0zhakqgar04r";
    owner = "angerman";
  };
in
  { nixpkgsPath ? pkgsPath }:

with import nixpkgsPath {
  crossSystem = (import <nixpkgs/lib>).systems.examples.mingwW64;
  config = import ./config.nix;
};
let
    Cabal_HEAD = buildPackages.haskell.packages.ghcHEAD.callPackage ./cabal-head.nix { };
    iserv-proxy = buildPackages.haskell.packages.ghcHEAD.iserv-proxy;
in {
  hello-world = pkgs.haskell.packages.ghcHEAD.callPackage ./hello-world.nix { inherit Cabal_HEAD; };
  dhall-json = pkgs.haskell.packages.ghcHEAD.callPackage ./dhall-json.nix { inherit Cabal_HEAD; };
  cross-ghc = haskell.packages.ghcHEAD.ghc;
  lens = haskell.packages.ghcHEAD.lens;
  double-conversion = haskell.packages.ghcHEAD.double-conversion;
  libiserv = haskell.packages.ghcHEAD.libiserv;
  remote-iserv = haskell.packages.ghcHEAD.remote-iserv;
  trifecta = haskell.packages.ghcHEAD.trifecta;
  inherit Cabal_HEAD;
  inherit iserv-proxy;
  inherit pkgs;
}
