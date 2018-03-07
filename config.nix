let customizeGhc = oldGhc:
 let ghc = oldGhc.override {
   # override the version, revision and flavour to get a custom ghc.
   version = "8.5.20180306";
   ghcRevision = "1dfd7aa2cb06adccc9180463807e62260d66c90e";
   ghcSha256 = "13iygvpdsbwxphx89lcvp358z63rnah8gzyxzv20qik6vhh7nf2j";
   ghcCrossFlavour = "quick-cross-ncg";
   ghcFlavour = "quick";
 }; in ghc.overrideAttrs (drv: {
   # override the derivation attributes.
   # Specifically to set dontStrip.
   # name = "ghc-8.5.angerman";
   dontStrip = true;
   # patches = map fetchDiff ghcDiffs;
   hardeningDisable = [ "stackprotector" ];
 });
in
{
    packageOverrides = ps: rec {
      haskell.compiler = ps.haskell.compiler // {
        ghcHEAD = customizeGhc ps.haskell.compiler.ghcHEAD;
      };
      haskell.packages = ps.haskell.packages // {
        ghcHEAD = ps.haskell.packages.ghcHEAD.override {
          ghc = customizeGhc ps.buildPackages.haskell.compiler.ghcHEAD;
        };
        # Cabal_HEAD = ps.buildPackages.haskell.packages.ghcHEAD.callPackage ./cabal-head.nix { };

      };
      # TODO: Inject Cabal_HAED into setupHaskellDepends by default.
      #
      # // ps.lib.optionalAttrs (ps.hostPlatform != ps.buildPlatform) {
      #   mkDerivation = drv: super.mkDerivation (drv // {
      #     setupHaskellDepends = (drv.setupHaskellDepends or []) ++ [
      #       self.ghc.bootPkgs.Cabal
      #     ];
      #   });
      # };
    };
}
