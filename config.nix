let customizeGhc = oldGhc:
let ghc = oldGhc.override {
  # override the version, revision and flavour to get a custom ghc.
  version = "8.5.20180313";
  ghcRevision = "d0d02e2887ccdc3563661410c5fdc897fa6ba074";
  ghcSha256 = "0dzv9152p95xzlr6wimyqmhdffcv15kfl5v2ng522qxsg2y4ixlq";
  ghcCrossFlavour = "quick-cross-ncg";
  ghcFlavour = "quick";
}; in ghc.overrideAttrs (drv: {
  # override the derivation attributes.
  # Specifically to set dontStrip.
  # name = "ghc-8.5.angerman";
  dontStrip = true;
  # patches = map fetchDiff ghcDiffs;
  hardeningDisable = [ "stackprotector" ];
  patches = [ ./ghc-d0d02e28.patch ];
});

in
{
  packageOverrides = ps: rec {
    libyaml = ps.libyaml.overrideAttrs (drv: { patches = [ ./libyaml.patch ]; });

    haskell.compiler = ps.haskell.compiler // {
      ghcHEAD = customizeGhc ps.haskell.compiler.ghcHEAD;
    };
    haskell.packages = ps.haskell.packages //
      (let
      addLibraryDepends = drv: xs: ps.haskell.lib.overrideCabal drv (drv: { libraryHaskellDepends = (drv.libraryHaskellDepends or []) ++ xs; });
      Cabal_HEAD = ps.buildPackages.haskell.packages.ghcHEAD.callPackage ./cabal-head.nix { };
    in {
        ghcHEAD = ps.haskell.packages.ghcHEAD.override {
          overrides = self: super: {
      	    ghc = customizeGhc ps.buildPackages.haskell.compiler.ghcHEAD;

            mkDerivation = drv: super.mkDerivation (drv // {
              enableSharedLibraries = false; 
              enableSharedExecutables = false;
              setupHaskellDepends = (drv.setupHaskellDepends or []) ++
                ps.lib.optionals (ps.hostPlatform != ps.buildPlatform) [ Cabal_HEAD ];
              hardeningDisable = [ "stackprotector" ];
            doHaddock = false;
            dontStrip = true;
            });

          zlib = ps.haskell.lib.overrideCabal super.zlib (drv: {
            version = "0.6.2";
            sha256 = "1vbzf0awb6zb456xf48za1kl22018646cfzq4frvxgb9ay97vk0d";
          });

            lens = let l = ps.haskell.lib.overrideCabal super.lens (drv: {
              version = "4.16";
              sha256 = "16wz3s62zmnmis7xs9jahyc7b75090b96ayk98c3gvzmpg7bx54z";
            }); in let l2 = ps.haskell.lib.appendPatch l ./lens.patch;
            in ps.haskell.lib.overrideCabal l2 (drv: { doVerbose = true; });


          # patches from head.hackage.
          text = ps.haskell.lib.appendPatch super.text ./head.hackage/patches/text-1.2.2.2.patch;
          blaze-builder = ps.haskell.lib.appendPatch super.blaze-builder ./head.hackage/patches/blaze-builder-0.4.0.2.patch;
          unordered-containers = ps.haskell.lib.appendPatch super.unordered-containers ./head.hackage/patches/unordered-containers-0.2.8.0.patch;
          semigroupoids = ps.haskell.lib.appendPatch super.semigroupoids ./head.hackage/patches/semigroupoids-5.2.1.patch;
          free = ps.haskell.lib.appendPatch super.free ./head.hackage/patches/free-4.12.4.patch;
          x509 = ps.haskell.lib.appendPatch super.x509 ./x509-1.7.2.patch;
          x509-store = ps.haskell.lib.appendPatch super.x509-store ./head.hackage/patches/x509-store-1.6.5.patch;
#              in let p = ps.haskell.lib.appendPatches l [
#                #            ./head.hackage/patches/lens-4.15.4.patch
#                ./lens.patch
#              ]; in ps.haskell.lib.overrideCabal p (drv: { doVerbose = true; });

          tls = ps.haskell.lib.appendPatch super.tls ./head.hackage/patches/tls-1.4.0.patch;

          # --allow-newer :-(
          integer-logarithms = ps.haskell.lib.appendPatch super.integer-logarithms ./integer-logarithms.patch;
          async = ps.haskell.lib.appendPatch super.async ./async.patch;
          bifunctors = ps.haskell.lib.appendPatch super.bifunctors ./bifunctors.patch;
          unliftio-core = ps.haskell.lib.appendPatch super.unliftio-core ./unliftio-core.patch;
          cabal-doctest = ps.haskell.lib.appendPatch super.cabal-doctest ./cabal-doctest.patch;
          th-abstraction = ps.haskell.lib.appendPatch super.th-abstraction ./th-abstraction.patch;

          #other patches
          system-fileio = ps.haskell.lib.appendPatch super.system-fileio ./system-fileio.patch;
            double-conversion = let p2 = (let p = ps.haskell.lib.appendPatch super.double-conversion ./double-conversion.patch;
            in ps.haskell.lib.overrideCabal p (drv: { doVerbose = true; }));
            in ps.haskell.lib.appendConfigureFlag p2 [ "-v0" ];
          StateVar = ps.haskell.lib.appendPatch super.StateVar ./StateVar.patch;

          mtl = ps.haskell.lib.overrideCabal super.mtl (drv: { libraryHaskellDepends = [ self.base self.transformers ]; });

          contravariant = ps.haskell.lib.appendPatch super.contravariant ./contravariant-1.4.1.patch;
          # missing libraries, due to os(mingw32) check not executed in cabal2nix
          http-client = addLibraryDepends super.http-client [ self.safe ]; # self.Win32 ];
          ansi-terminal = addLibraryDepends super.ansi-terminal [ self.base-compat self.containers ]; #self.Win32 ];
          # disable integer-gmp on cryptonite
          cryptonite = ps.haskell.lib.appendConfigureFlag super.cryptonite [ "-f-integer-gmp" ];

          # disable executables where needed
          aeson-pretty = ps.haskell.lib.overrideCabal super.aeson-pretty (drv: { enableSharedExecutables = false; doVerbose = true; });
          yaml = let p = ps.haskell.lib.overrideCabal         super.yaml         (drv: { enableSharedExecutables = false; }); in ps.haskell.lib.dontStrip p;


          # no stripping
          attoparsec = ps.haskell.lib.dontStrip super.attoparsec;
          aeson = ps.haskell.lib.dontStrip super.aeson;
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
