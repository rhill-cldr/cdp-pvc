{ jdk ? "jdk11" }:

let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { inherit jdk; };
in
with pkgs;
pkgs.mkShell {
  buildInputs = [
    direnv
    pkgs.${jdk}
    python39Full
    python39Packages.ansible-runner
    python39Packages.PyLD
    python39Packages.pipx
    python39Packages.pytest
    python39Packages.pyhocon
    python39Packages.pyparsing
    python39Packages.sphinx
    python39Packages.tox
    metal-cli
    terraform
  ];
}

