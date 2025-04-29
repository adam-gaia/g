{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true; # nix
    deadnix.enable = true; # nix
    #typos.enable = true; # spellcheck # Disabled until https://github.com/numtide/treefmt/issues/198 is fixed
  };
}
