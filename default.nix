{ nixpkgsPath ?
  import ./fetchNixpkgs.nix {
    rev = "c8f682e7cc3d75066beab1ffa8696c45ec4dab3f";
    sha256 = "1v1jza5j3y9x067gl9lpn1g4w90swpjgydn3n1wnkxwndrn52z9h";
    sha256unpacked = "0dv29399nf6b5qhl16hkcaz71kwjn3mv2m2ydc8p0zhakqgar04r";
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
}
