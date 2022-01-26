{
  description = "A (very) minimalist nix flake lib for printing a help message in your shell";

  outputs = { self, ... }:
    let
      # inherit (nixpkgs) lib;

      # Colors
      nc = "\\e[0m";
      white = "\\e[1;37m";
    in
    {
      lib = {
        mkHelp = { flake, name, system, writeScript, additionalCommands ? {}, supplementalNotes ? "" }:
          let
            appsHelp =
              builtins.attrValues
                (builtins.mapAttrs
                  (name: app: "${white}nix run .#${name}${nc}\t${app.description}")
                  flake.apps.${system});

            additionalHelp = 
              builtins.attrValues
                (builtins.mapAttrs
                  (command: description: "${white}${command}${nc}\t${description}")
                  additionalCommands);

            # An awful hack, for now
            rawFlake = import "${flake.outPath}/flake.nix";
          in
          writeScript "help" ''
            echo '${name}: ${rawFlake.description}'
            echo
            echo 'APPS:'
            echo
            column -t -s $'\t' <(printf '${builtins.concatStringsSep "\n" appsHelp}') \
              | while read -r line ; do printf "\t$line\n" ; done
            echo

            echo 'ADDITIONAL COMMANDS:'
            echo
            column -t -s $'\t' <(printf '${builtins.concatStringsSep "\n" additionalHelp}') \
              | while read -r line ; do printf "\t$line\n" ; done

            echo
            printf '${supplementalNotes}'
          '';
      };
    };
}
