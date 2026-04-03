{
  description = "Meow-like modal key bindings for the fish shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.devshell.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          self',
          config,
          pkgs,
          ...
        }:
        {
          packages = {
            fish-meow = pkgs.fishPlugins.buildFishPlugin {
              pname = "fish-meow";
              version = "0-unstable";
              src = inputs.self;
              meta = {
                description = "Meow-like modal key bindings for the fish shell";
                homepage = "https://github.com/laxect/fish-meow";
                license = pkgs.lib.licenses.unlicense;
                platforms = pkgs.lib.platforms.unix;
              };
            };
            default = self'.packages.fish-meow;
            testShell = pkgs.wrapFish {
              pluginPkgs = [ self'.packages.fish-meow ];
            };
          };

          checks = {
            syntax =
              pkgs.runCommand "fish-meow-syntax-check"
                {
                  nativeBuildInputs = [ pkgs.fish ];
                }
                ''
                  find ${inputs.self}/functions ${inputs.self}/tests -name '*.fish' \
                    | xargs fish --no-execute
                  touch $out
                '';
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            tests = pkgs.stdenv.mkDerivation {
              pname = "fish-meow-tests";
              version = "0-unstable";
              src = inputs.self;
              nativeBuildInputs = with pkgs; [
                fish
                tmux
                inotify-tools
                perl
              ];
              dontBuild = true;
              doCheck = true;
              checkPhase = ''
                runHook preCheck
                fish ./run-tests
                runHook postCheck
              '';
              # Tests produce no build output; stamp file satisfies Nix
              installPhase = "touch $out";
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.fish_indent.enable = true;
          };

          devshells.default = {
            devshell.name = "fish-meow";
            packages =
              with pkgs;
              [
                fish
                tmux
                perl
                config.treefmt.build.wrapper
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ inotify-tools ];
            commands = [
              {
                name = "run-tests";
                command = "fish ${inputs.self}/run-tests";
                help = "run the full test suite";
                category = "development";
              }
            ];
          };
        };
    };
}
