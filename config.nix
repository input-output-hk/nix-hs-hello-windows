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
      libyaml = ps.libyaml.overrideAttrs (drv: { patches = [ ./libyaml.patch ]; });

      haskell.compiler = ps.haskell.compiler // {
        ghcHEAD = customizeGhc ps.haskell.compiler.ghcHEAD;
      };
      haskell.packages = ps.haskell.packages //
        (let addLibraryDepends = drv: xs: ps.haskell.lib.overrideCabal drv (drv: { libraryHaskellDepends = (drv.libraryHaskellDepends or []) ++ xs; });
        in { ghcHEAD = ps.haskell.packages.ghcHEAD.override {
          overrides = self: super: {
      	    ghc = customizeGhc ps.buildPackages.haskell.compiler.ghcHEAD;

            mkDerivation = drv: super.mkDerivation (drv // {
              enableSharedLibraries = false; 
              enableSharedExecutables = false;
#              setupHaskellDepends = (drv.setupHaskellDepends or []) ++ [ self.Cabal_HEAD ];
              hardeningDisable = [ "stackprotector" ];
              doHaddock = false;
            });
            text = ps.haskell.lib.appendPatch super.text ./head.hackage/patches/text-1.2.2.2.patch;
            blaze-builder = ps.haskell.lib.appendPatch super.blaze-builder ./head.hackage/patches/blaze-builder-0.4.0.2.patch;
            unordered-containers = ps.haskell.lib.appendPatch super.unordered-containers ./head.hackage/patches/unordered-containers-0.2.8.0.patch;

            cabal-doctest = ps.haskell.lib.appendPatch super.cabal-doctest ./cabal-doctest.patch;
            system-fileio = ps.haskell.lib.appendPatch super.system-fileio ./system-fileio.patch;
            th-abstraction = ps.haskell.lib.appendPatch super.th-abstraction ./th-abstraction.patch;

            ansi-terminal = addLibraryDepends super.ansi-terminal [ self.base-compat self.containers ]; #self.Win32 ];
            double-conversion = ps.haskell.lib.appendPatch super.double-conversion ./double-conversion.patch;
#             Cabal_HEAD = self.callPackage ./cabal-head.nix { };
         };
       };
      });
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
