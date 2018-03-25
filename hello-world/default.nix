{ mkDerivation, base, stdenv }:
mkDerivation {
  pname = "hs-hello";
  version = "1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  enableSharedExecutables = false;
  executableHaskellDepends = [ base ];
  license = stdenv.lib.licenses.bsd3;

  hardeningDisable = [ "stackprotector" ];
}
