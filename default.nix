let
  pkgsPath = import ./fetchNixpkgs.nix {
    rev = "6fe29bd1be20e3d0400c175be75eca4b55b81020";
    sha256 = "1z13fd1lvns4alghkyha4dvjk62mizy3kkxyli2iglzhasfjkwz6";
    sha256unpacked = "05f6g9a5m7csy7v1mpd6jpcsmyzsw6zk0s50n9sv4h5jlbdchmr1";
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
  inherit Cabal_HEAD;
  inherit iserv-proxy;
  inherit pkgs;
}
