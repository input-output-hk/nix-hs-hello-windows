{ mkDerivation, base, stdenv, Cabal_HEAD }:
mkDerivation {
  pname = "hs-hello";
  version = "1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  enableSharedExecutables = false;
  setupHaskellDepends = [ Cabal_HEAD ];
  executableHaskellDepends = [ base ];
  license = stdenv.lib.licenses.bsd3;

  hardeningDisable = [ "stackprotector" ];
}
