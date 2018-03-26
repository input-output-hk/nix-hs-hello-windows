{ nixpkgsPath ?
  import ./fetchNixpkgs.nix {
    rev = "c083187d18d49db70586ff882bbae83dd7e31206";
    sha256 = "10c7vd2j3q645bra2yy5kzh7fx7whxjxr5can913w7fndaipwzwr";
    sha256unpacked = "0advbxpmkfj6ziibjcfw41cvwpdkvhf4qx0g8d3qlm2nz3pzcbck";
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

  pthreads = pkgs.windows.mingw_w64_pthreads.overrideAttrs (attrs: { hardeningDisable = [ "stackprotector"]; });
}
