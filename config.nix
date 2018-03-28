{
  # This should work on linux and macOS.
  # wineWoW would be 32+64bit.  We can
  # probably get by with 64bit only.
  wine.build = "wine64";

  packageOverrides = ps: with ps; rec {

    windows = ps.windows // {
      # Disable the stackprotector on for ptheads. Otherwise the libwinpthread-1.dll will depend on
      # the libssp-0.dll in addition to KERNEL32.dll and msvcrt.dll.  This can be seen with either:
      #
      # > dumpbin /imports libwinpthread-1.dll | findstr .dll
      #
      # or
      #
      # $ strings libwinpthread-1.dll | grep "\.dll$"
      #
      # Thus we disable stackprotector, so that we can just copy the libwinpthread-1.dll next to
      # our binary and don't need to find and copy the libssp-0.dll from gcc as well.
      mingw_w64_pthreads = ps.windows.mingw_w64_pthreads.overrideAttrs (attrs: { hardeningDisable = [ "stackprotector"]; });
    };

    libyaml = ps.libyaml.overrideAttrs (drv: { patches = [ ./patches/libyaml.patch ]; });

    haskell.lib = ps.haskell.lib // (with ps.haskell.lib; {
      # sanity
      addExtraLibrary'  = ls: drv: addExtraLibrary drv ls;
      addBuildDepends'  = ds: drv: addBuildDepends drv ds;
      appendBuildFlags' = fs: drv: appendBuildFlags drv fs;
      overrideCabal'    = os: drv: overrideCabal drv os;
      addBuildTools'    = ts: drv: addBuildTools drv ts;
      addPreBuild'      = x: drv:  overrideCabal drv (drv: { preBuild  = (drv.preBuild or  "") + x; });
      addPostBuild'     = x: drv:  overrideCabal drv (drv: { postBuild = (drv.postBuild or "") + x; });
    });

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
        overrides = self: super: rec {

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

          # Logic to run TH via an external interpreter (64bit windows via wine64)
          doTemplateHaskell = pkg: with haskell.lib; let
            buildTools = [ buildHaskellPackages.iserv-proxy buildPackages.winePackages.minimal ];
            buildFlags = map (opt: "--ghc-option=" + opt) [
              "-fexternal-interpreter"
              "-pgmi" "${buildHaskellPackages.iserv-proxy}/bin/iserv-proxy"
              "-opti" "127.0.0.1" "-opti" "$PORT"
              # TODO: this should be automatically injected based on the extraLibrary.
              "-L${windows.mingw_w64_pthreads}/lib"
            ];
            preBuild = ''
              PORT=$((5000 + $RANDOM % 5000))
              echo "---> Starting remote-iserv on port $PORT"
              WINEPREFIX=$TMP ${buildPackages.winePackages.minimal}/bin/wine64 ${self.remote-iserv}/bin/remote-iserv.exe tmp $PORT &
              sleep 5 # wait for wine to fully boot up...
              RISERV_PID=$!
            '';
            postBuild = ''
              echo "---> killing remote-iserv..."
              kill $RISERV_PID
            ''; in
            appendBuildFlags' buildFlags
             (addBuildDepends' [ self.remote-iserv ]
              (addExtraLibrary' windows.mingw_w64_pthreads
               (addBuildTools' buildTools
                (addPreBuild' preBuild
                 (addPostBuild' postBuild pkg)))));

          # --------------------------------------------------------------------------------

          hello-world = self.callPackage ./hello-world { };

          # iserv logic
          libiserv = with haskell.lib; addExtraLibrary (enableCabalFlag (self.hackageCandidate "libiserv" "8.5" {}) "network") self.network;
          iserv-proxy = self.hackageCandidate "iserv-proxy" "8.5" { libiserv = self.libiserv; };
          # TODO: Why is `network` not properly propagated from `libiserv`?
          remote-iserv = with haskell.lib; let pkg = addExtraLibrary (self.hackageCandidate "remote-iserv" "8.5" { libiserv = self.libiserv; }) self.network; in
            overrideCabal (addBuildDepends pkg [ windows.mingw_w64_pthreads ]) (drv: {
            postInstall = ''
              cp ${windows.mingw_w64_pthreads}/bin/libwinpthread-1.dll $out/bin/
            '';
          });

          mtl = ps.haskell.lib.overrideCabal super.mtl (drv: { libraryHaskellDepends = [ self.base self.transformers ]; });

          # missing libraries, due to os(mingw32) check not executed in cabal2nix
          http-client = ps.haskell.lib.addBuildDepends super.http-client [ self.safe ]; # self.Win32 ];
          ansi-terminal = ps.haskell.lib.addBuildDepends super.ansi-terminal [ self.base-compat self.containers ]; #self.Win32 ];
          # disable integer-gmp on cryptonite
          cryptonite = ps.haskell.lib.appendConfigureFlag super.cryptonite [ "-f-integer-gmp" ];

          # Template Haskell
          trifecta = with ps.haskell.lib;
          if ps.hostPlatform == ps.buildPlatform then super.trifecta else (doTemplateHaskell super.trifecta);

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
