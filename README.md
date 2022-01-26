# Generate a tiny help utility for your flake

This is an attempt to use the existing flake schema for building a little terminal help utility.

**Fair warning:**
Unfortunately this currently relies on a bit of an awful hack for pulling the description attribute out of your `flake.nix` file.
Furthermore, app `description` attributes aren't specified as part of the normal flake schema.
That is to say, this is all very unlikely to be future proof as is!

You may want to take a look at [numtide's devshell](https://numtide.github.io/devshell/) for something more serious.

In short:

```nix
flake-help.lib.mkHelp {
  name = "my-flake";
  flake = self;
  inherit system;
  inherit (pkgs) writeScript;
  additionalCommands = {
    "command" = "description";
  };
  supplementalNotes = ''
    Extra notes at the end of the help message
  '';
}
```

Example usage:

```nix
{
  description = "An example flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-help.url = "github:rehno-lindeque/flake-help";
  };

  outputs = { self, nixpkgs, flake-utils, flake-help, ... }:
    let
      inherit (nixpkgs) lib;

      eachEnvironment = f: flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ]
        (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
          }
        );

        # Terminal colors
        nc = "\\e[0m"; # No Color
        white = "\\e[1;37m";
        blue = "\\e[1;34m";
    in
    eachEnvironment ({ pkgs, system }: {

      devShell = pkgs.mkShell {
        shellHook =
          ''
            export PS1='${blue}[$(basename $PWD)]$ ${nc}'
            clear -x
            printf "${white}"
            echo "-------------------------------"
            echo "Project development environment"
            echo "-------------------------------"
            printf "${nc}"
            echo
            nix run .#help 2>/dev/null
          '';
      };

      packages = {
        hello-octopus = pkgs.writeScript "hello-octopus" ''printf '🐙 ' && ${pkgs.hello}/bin/hello "$@"'';
        help = flake-help.lib.mkHelp {
          name = "hello-octopus";
          flake = self;
          inherit system;
          inherit (pkgs) writeScript;
          additionalCommands = {
            "nix run .#say-hello -- -g \"Hello $(whoami)!\"" = "A more personal greeting";
          };
          supplementalNotes = ''
            This has been your help message...

            Have fun!
            🐙
          '';
        };
      };

      apps = {
        help = {
          type = "app";
          description = "display this help message";
          program = "${self.packages.${system}.help}";
        };

        say-hello = {
          type = "app";
          description = "a friendly greeting";
          program = "${self.packages.${system}.hello-octopus}";
        };
      };

    }) // {

      checks = self.packages;

    };
}
```

```
-------------------------------
Project development environment
-------------------------------

hello-octopus: An example flake

APPS:

	nix run .#help       display this help message
	nix run .#say-hello  a friendly greeting

ADDITIONAL COMMANDS:

	nix run .#say-hello -- -g "Hello $(whoami)!"  A more personal greeting

This has been your help message...

Have fun!
🐙
[hello-octopus]$ nix run .#say-hello
🐙 Hello, world!
[hello-octopus]$ nix run .#say-hello -- -g "Hello $(whoami)!"
🐙 Hello me!
```
