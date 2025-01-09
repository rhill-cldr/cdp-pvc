{
  description = "Provision machines in CloudCat";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    # Helpers for system-specific outputs
    flake-utils.url = "github:numtide/flake-utils";
    
  };

  outputs = { self, nixpkgs, flake-utils }: {
    defaultPackage.x86_64-darwin = self.packages.x86_64-darwin.cloudera-setup;

    packages.x86_64-darwin.cloudera-setup = 
      let
	pkgs = import nixpkgs { system = "x86_64-darwin"; };
        var-name = "cloudera-setup";
        var-source = builtins.readFile ./deploy.sh;
        setup-machines = (pkgs.writeScriptBin var-name var-source).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
        ansible-runner = (pkgs.python310Packages.ansible-runner).overridePythonAttrs(old: {
          doCheck = false;
        });
        var-buildInputs = with pkgs; [
          jdk11_headless
          python310Full
          python310Packages.PyLD
          python310Packages.pipx
          python310Packages.pytest
          python310Packages.pyhocon
          python310Packages.pyparsing
          python310Packages.sphinx
          python310Packages.tox
          ansible-runner
        ]; 
      in pkgs.symlinkJoin {
        name = var-name;
        paths = [ setup-machines ] ++ var-buildInputs;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/${var-name} --prefix PATH : $out/bin";
      };
  };
}

