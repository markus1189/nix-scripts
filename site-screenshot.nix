{ hostNix ? import <nixpkgs> {}
, compiler ? "ghc883"
}:

with rec {
  nixpkgs = import (hostNix.pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    rev = "33496aa3a6f3f731e9595c41bb1b72f2bdfd1d90";
    sha256 = "06pyjy8dln6kqgyiisy5x27n37d1gpbsmk5r85gpfp6200dvrkg8";
  }) {};
  seleniumServerJar = nixpkgs.fetchurl {
    url = "https://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar";
    sha256 = "1y3w1c2173vn2yqy6047l6lxmg919xyi19ccw4my7cm5bhx6vkhw";
  };
  haskellPackages = ps: with ps; [ webdriver typed-process temporary ];
  haskellDeps = (nixpkgs.haskell.packages.${compiler}.ghcWithPackages haskellPackages);
};

nixpkgs.mkShell {
  inherit seleniumServerJar;

  buildInputs = with nixpkgs; [
    haskellDeps
    adoptopenjdk-bin
    chromedriver
    chromium
  ];
}
