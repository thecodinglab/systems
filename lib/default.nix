{ inputs, outputs }:
let
  inherit (inputs.nixpkgs) lib;

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;

      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications

        inputs.hyprland.overlays.hyprland-packages
        inputs.hyprland.overlays.hyprland-extras
        inputs.tether.overlays.default
      ];

      config = {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "1password"
            "1password-cli"
            "spotify"
            "obsidian"

            # Work
            "slack"
            "postman"

            # AI
            "antigravity-cli"
            "claude-code"
            "claude-desktop"

            # Gaming
            "steam"
            "steam-unwrapped"
            "steam-original"
            "steam-run"
            "discord"

            # Server
            "plexmediaserver"

            # Nvidia
            "nvidia-kernel-modules"
            "nvidia-x11"
            "nvidia-settings"
            "cuda_cccl"
            "cuda_cudart"
            "cuda_nvcc"
            "libcublas"
          ];
      };
    };

  # Per-machine escape hatch: `inputs.local` points at ./local (empty) unless
  # overridden with `--override-input local path:<dir>` (see Makefile). For a
  # host <name> living in <hostDir>, `<dir>/<name>.nix` is added to the system
  # modules and `<dir>/<name>-home.nix` to the modules of the home-manager user
  # florian. Only hosts with a <hostDir>/home.nix have that user; checking the
  # file (instead of config.users.users) avoids an infinite recursion.
  localModules =
    hostDir: name:
    let
      file = suffix: "${inputs.local}/${name}${suffix}.nix";
      system = file "";
      home = file "-home";
      hasHome = builtins.pathExists (hostDir + "/home.nix");
    in
    lib.optional (builtins.pathExists system) system
    ++ lib.optional (builtins.pathExists home) (
      if hasHome then
        { home-manager.users.florian.imports = [ home ]; }
      else
        throw "local/${name}-home.nix: host ${name} has no home-manager user florian (no home.nix)"
    );

  # `keys` (lib/keys.nix) is also passed on to home-manager, see
  # modules/shared/home-manager.nix
  specialArgs = {
    inherit inputs outputs;
    keys = import ./keys.nix;
  };

  mkNixosFrom =
    dir: name:
    lib.nixosSystem {
      pkgs = pkgsFor "x86_64-linux";
      inherit specialArgs;
      modules = lib.attrValues outputs.nixosModules ++ [ dir ] ++ localModules dir name;
    };
in
{
  inherit pkgsFor localModules;

  # hosts/<name>/default.nix
  mkDarwin =
    name:
    let
      dir = ../hosts/${name};
    in
    inputs.darwin.lib.darwinSystem {
      pkgs = pkgsFor "aarch64-darwin";
      inherit specialArgs;
      modules = lib.attrValues outputs.darwinModules ++ [ dir ] ++ localModules dir name;
    };

  # hosts/<name>/default.nix
  mkNixos = name: mkNixosFrom ../hosts/${name} name;

  # hosts/containers/<name>/default.nix
  mkContainer = name: mkNixosFrom ../hosts/containers/${name} name;
}
