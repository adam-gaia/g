{
  flake,
  inputs,
  perSystem,
  pkgs,
}: let
  # Treefmt doesn't easily expose the programs with out its flake-parts module (as far as I can tell)
  # This snipit, modified from their default.nix, lets us grab the programs after building with our treefmt config
  treefmt-module-builder = nixpkgs: configuration: let
    mod = inputs.treefmt-nix.lib.evalModule nixpkgs configuration;
  in
    mod.config.build;
  treefmt-module = treefmt-module-builder pkgs (import ../treefmt.nix);
  treefmt-bin = treefmt-module.wrapper;
  treefmt-programs = lib.attrValues treefmt-module.programs;

  pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.system}.run {
    src = ../../.;
    hooks = {
      treefmt = {
        enable = true;
        package = treefmt-bin;
      };
    };
  };
in
  pkgs.mkShellNoCC {
    packages =
      [

      ]
      # Include treefmt and formatters
      ++ treefmt-programs
      ++ [treefmt-bin];

    shellHook = ''
      export PRJ_ROOT="$(git rev-parse --show-toplevel)"

      # Create .pre-commit-config.yaml
      ${pre-commit-check.shellHook}
    '';
  }
