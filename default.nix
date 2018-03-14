let
  pkgsPath = import ./fetchNixpkgs.nix {
    rev = "ff9275c2886a1d984bf9a20ef7871b65d85aa08f";
    sha256 = "0c8nwx1ghl6p1z0wv8rf02f1zgvry66q3jn3xk74dw578avnsfvy";
    sha256unpacked = "1mz15byiv0fb0iyjb245c0q613ipmklmbzx4wb74i8lvmfwa3cwr";
    owner = "angerman";
  };
in
  { nixpkgsPath ? pkgsPath }:

with import nixpkgsPath {
  crossSystem = (import <nixpkgs/lib>).systems.examples.mingwW64;
  config = import ./config.nix;
};
let Cabal_HEAD = buildPackages.haskell.packages.ghcHEAD.callPackage ./cabal-head.nix { };
in {
  hello-world = pkgs.haskell.packages.ghcHEAD.callPackage ./hello-world.nix { inherit Cabal_HEAD; };
  dhall-json = pkgs.haskell.packages.ghcHEAD.callPackage ./dhall-json.nix { inherit Cabal_HEAD; };
  cross-ghc = haskell.packages.ghcHEAD.ghc;
  lens = haskell.packages.ghcHEAD.lens;
  double-conversion = haskell.packages.ghcHEAD.double-conversion;
  inherit Cabal_HEAD;
  inherit pkgs;
}
