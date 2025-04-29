{ pkgs }: let

  buildNushellScript = let
    nu = "${pkgs.nushell}/bin/nu";
  in
    {
      name,
      contents,
    }:
      pkgs.writeTextFile {
        inherit name;
        destination = "/bin/${name}";
        text = ''
          #!${nu}

          ${contents}
        '';
        executable = true;
      };

  name = "g";
  contents = builtins.readFile ../g;

in
buildNushellScript {inherit name contents; }
