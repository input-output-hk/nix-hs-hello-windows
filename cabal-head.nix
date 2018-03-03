{ mkDerivation, pkgs, array, base, binary, bytestring, containers
, deepseq, directory, filepath, pretty, process, QuickCheck, tagged
, tasty, tasty-hunit, tasty-quickcheck, time, unix, stdenv }:
mkDerivation {
       pname = "Cabal";
       version = "2.3.0.0";
       src = pkgs.fetchgit {
        url = "https://github.com/zw3rk/cabal.git";
        rev = "d8f21cdc229304e41005eb223e05603da190df8f";
        sha256 = "1schvsjyhz25imiiqzzqwsy2b5hlxy7gz2q8ifvjk99xyzzkbpgi";
        # extracting the "Cabal" subfolder from the checkout.
        # this is terrible :(
        postFetch = ''
        mv "$out" "$out.bck"
        mv "$out.bck/Cabal" "$out"
        rm -fR "$out.bck"
        '';
       };
       # The program 'haddock' version >=2.0 is required
       doHaddock = false;
       #sha256 = "06rx6jxikqrdf7k6pmam5cvhwnagq6njmb9qm5777nrz278ccaw0";
       libraryHaskellDepends = [
         array base binary bytestring containers deepseq directory filepath
         pretty process time unix
       ];
       testHaskellDepends = [
         array base containers directory filepath pretty QuickCheck tagged
         tasty tasty-hunit tasty-quickcheck
       ];
       doCheck = false;
       homepage = "http://www.haskell.org/cabal/";
       description = "A framework for packaging Haskell software";
       license = stdenv.lib.licenses.bsd3;
       hydraPlatforms = stdenv.lib.platforms.none;
}
