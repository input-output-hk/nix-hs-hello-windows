{
  packageOverrides = ps: rec {
    libyaml = ps.libyaml.overrideAttrs (drv: { patches = [ ./patches/libyaml.patch ]; });

    haskell.lib = ps.haskell.lib;
    haskell.compiler = ps.haskell.compiler // {
      myGhc = (ps.haskell.compiler.ghcHEAD.override {
        # override the version, revision and flavour to get a custom ghc.
        version = "8.5.20180313";
        ghcRevision = "d0d02e2887ccdc3563661410c5fdc897fa6ba074";
        ghcSha256 = "0dzv9152p95xzlr6wimyqmhdffcv15kfl5v2ng522qxsg2y4ixlq";
        ghcCrossFlavour = "quick-cross-ncg";
        ghcFlavour = "quick";
      } // ps.lib.optionalAttrs (ps.targetPlatform != ps.hostPlatform) {
          # bootPackages = ps.buildPackages.haskell.packages.myGhc;
        }).overrideAttrs (drv: {
        # override the derivation attributes.
        # Specifically to set dontStrip.
        # name = "ghc-8.5.angerman";
        dontStrip = true;
        # patches = map fetchDiff ghcDiffs;
        hardeningDisable = [ "stackprotector" ];
        patches = [ ./patches/ghc-d0d02e28.patch ];
      });
    };

    haskell.packages = ps.haskell.packages // {
      cabal-doctest = null;
      myGhc = ps.haskell.packages.ghcHEAD.override rec {

        ghc = ps.buildPackages.haskell.compiler.myGhc;
        buildHaskellPackages = ps.buildPackages.haskell.packages.myGhc;
        overrides = self: super: {

          # Custom Cabal (required for windows support); and a Setup builder with the newer Cabal.
          Cabal = ps.haskell.lib.overrideCabal (self.callPackage ./cabal-head.nix { }) (drv: { enableSharedExecutables = false; enableSharedLibraries = false; });
          setup = args: super.setup (args // { setupHaskellDepends = [ self.Cabal ]; });
          # fetch a package candidate from hackage and return the cabal2nix expression.
          hackageCandidate = name: ver: args: self.callCabal2nix name (fetchTarball "https://hackage.haskell.org/package/${name}-${ver}/candidate/${name}-${ver}.tar.gz") args;

          # Custom derivation logic
          mkDerivation = drv: super.mkDerivation (drv // {
            doHaddock = false;
            hyperlinkSource = false;
            enableLibraryProfiling = false;
          } // ps.lib.optionalAttrs (ps.hostPlatform != ps.buildPlatform) {
              # setupHaskellDepends = (drv.setupHaskellDepends or []) ++
              #   ps.lib.optionals (drv.pname != "Cabal") [ buildHaskellPackages.Cabal ]
              #   ;
              enableSharedLibraries = false;
              enableSharedExecutables = false;
              hardeningDisable = [ "stackprotector" ];
              doHaddock = false;
              dontStrip = true;
            });

          hello-world = self.callPackage ./hello-world { };

          # iserv logic
          libiserv = with haskell.lib; addExtraLibrary (enableCabalFlag (self.hackageCandidate "libiserv" "8.5" {}) "network") self.network;
          iserv-proxy = self.hackageCandidate "iserv-proxy" "8.5" { libiserv = self.libiserv; };
          # TODO: Why is `network` not properly propagated from `libiserv`?
          remote-iserv = with haskell.lib; addExtraLibrary (self.hackageCandidate "remote-iserv" "8.5" { libiserv = self.libiserv; }) self.network;

          mtl = ps.haskell.lib.overrideCabal super.mtl (drv: { libraryHaskellDepends = [ self.base self.transformers ]; });

          # missing libraries, due to os(mingw32) check not executed in cabal2nix
          http-client = ps.haskell.lib.addBuildDepends super.http-client [ self.safe ]; # self.Win32 ];
          ansi-terminal = ps.haskell.lib.addBuildDepends super.ansi-terminal [ self.base-compat self.containers ]; #self.Win32 ];
          # disable integer-gmp on cryptonite
          cryptonite = ps.haskell.lib.appendConfigureFlag super.cryptonite [ "-f-integer-gmp" ];

          # Template Haskell
          trifecta = with ps.haskell.lib;
          if ps.hostPlatform == ps.buildPlatform then super.trifecta else
            appendBuildFlags (addExtraLibrary (overrideCabal super.trifecta (drv: { buildTools = [ buildHaskellPackages.iserv-proxy ]; })) ps.windows.mingw_w64_pthreads )
            [ "--ghc-option=-fexternal-interpreter"
              "--ghc-option=-fexternal-interpreter"
              "--ghc-option=-pgmi"
              "--ghc-option=${buildHaskellPackages.iserv-proxy}/bin/iserv-proxy"
              "--ghc-option=-opti"
              # TODO: Do not hardcode IP / PORT
              "--ghc-option=10.0.1.22"
              "--ghc-option=-opti"
              "--ghc-option=5001"
              "--ghc-option=-opti"
              "--ghc-option=-v "
              # TODO: this should be automatically injected based on the extraLibrary. See above.
              "--ghc-option=-L${ps.windows.mingw_w64_pthreads}/lib"
          ];
        } // (with ps.haskell.lib; {
          # lift version bounds
          async         = doJailbreak super.async;
          cabal-doctest = doJailbreak super.cabal-doctest;
        }) // (with ps.haskell.lib; {
          # patches (mostly for HEAD compatibility)
          system-fileio     = appendPatch super.system-fileio     ./patches/system-fileio.patch;
          text-format       = appendPatch super.text-format       ./patches/text-format-0.3.1.1.patch;
          x509-system       = appendPatch super.x509-system       ./patches/x509-system-1.6.6.patch;
          streaming-commons = appendPatch super.streaming-commons ./patches/streaming-commons-0.1.19.patch;
          double-conversion = appendPatch super.double-conversion ./patches/double-conversion.patch;
          StateVar          = appendPatch super.StateVar          ./patches/StateVar.patch;
          contravariant     = appendPatch super.contravariant     ./patches/contravariant-1.4.1.patch;
        });
      };
    };
  };
}
