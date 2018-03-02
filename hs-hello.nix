with import <nixpkgs> { crossSystem = (import <nixpkgs/lib>).systems.examples.mingwW64;
                        config = import ./config.nix; };
let Cabal_HEAD = buildPackages.haskell.packages.ghcHEAD.callPackage ./cabal-head.nix { };
in pkgs.haskell.packages.ghcHEAD.callPackage ./default.nix { inherit Cabal_HEAD; }
