     { mkDerivation, aeson, aeson-pretty, base, bytestring, dhall
     , optparse-generic, text, trifecta, vector, yaml, Cabal_HEAD
     , stdenv
     }:
     mkDerivation {
       pname = "dhall-json";
       version = "1.0.9";
       sha256 = "0xxgvsv8maccf81mdip1jnw4y3jlpnjhhxvyp4d3ph0xnng7z9l6";
       isLibrary = true;
       isExecutable = true;
       libraryHaskellDepends = [ aeson base dhall text vector ];
       executableHaskellDepends = [
         aeson aeson-pretty base bytestring dhall optparse-generic text
         trifecta yaml
       ];
       description = "Compile Dhall to JSON or YAML";
       license = stdenv.lib.licenses.bsd3;

       enableSharedExecutables = false;
       setupHaskellDepends = [ Cabal_HEAD ];
       hardeningDisable = [ "stackprotector" ];

     }