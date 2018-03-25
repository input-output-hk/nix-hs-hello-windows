{ nixpkgsPath ?
  import ./fetchNixpkgs.nix {
    rev = "8df80dbe09df6c9d11a2aec9d0a31320906f2559";
    sha256 = "0ca7dsqyli7grniv8lr71p01a3iabyz64cfa7rgkm2g9qhsvhv2w";
    sha256unpacked = "03kaldvp96z3py9imckn0h96nw176nz8qsanf6jn6vwws03sqpy5";
    owner = "angerman";
  }
}:

with import nixpkgsPath {
  crossSystem = (import <nixpkgs/lib>).systems.examples.mingwW64;
  config = import ./config.nix;
};
{
  inherit pkgs;

  inherit (haskell.packages.myGhc)
    hello-world
    dhall-json
    lens
    double-conversion
    libiserv
    remote-iserv
    trifecta
    ;
  inherit (buildPackages.haskell.packages.myGhc)
    Cabal
    iserv-proxy
    ;
  cross-ghc = haskell.packages.myGhc.ghc;
  cross-Cabal = haskell.packages.myGhc.Cabal;
  setup = buildPackages.haskell.packages.myGhc.setup {};
}
