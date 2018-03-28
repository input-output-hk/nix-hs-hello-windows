{ nixpkgsPath ?
  import ./fetchNixpkgs.nix {
    rev = "253aed86cc0fc8c27e46561deb0a3031a4c34bc6";
    sha256 = "1lg31agk2b1sb51h4ydni7lp6kkg98359jpcz4acr1rhrcql39fq";
    sha256unpacked = "0h2bl9k0r708z0gsj062mzn3w22v1g9nni37q65xscnjgrfvy987";
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
    cabal2nix
    ;
  cross-ghc = haskell.packages.myGhc.ghc;
  cross-Cabal = haskell.packages.myGhc.Cabal;
  setup = buildPackages.haskell.packages.myGhc.setup {};
  pthreads = pkgs.windows.mingw_w64_pthreads;
  wine = buildPackages.winePackages.minimal;

}
