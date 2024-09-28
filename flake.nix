{
  description = "RiseupVPN Configurator";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;

        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;# mkPoetryEnv;

        # pythonEnv = mkPoetryEnv {
        #   # python = pkgs.python311;
        #   projectDir = ./.;
        # };
      in
      {
        packages = {
          riseup-vpn-configurator = mkPoetryApplication { projectDir = self; };
          default = self.packages.${system}.riseup-vpn-configurator;
        };

        # Shell for app dependencies.
        #
        #     nix develop
        #
        # Use this shell for developing your app.
        devShells.default =
          let
            envVars = [ "RISEUP_WORKING_DIR=./files" "RISEUP_CONFIG_FILE=./files/riseup-vpn.yaml" "RISEUP_OVPN_FILE=./files/riseup.ovpn" ];
            shellVars = lib.concatStringsSep " " envVars;
            exportShellVars = lib.concatStringsSep "\n" (map (e: "export ${e}") envVars);
            sudoWithVars = pkgs.writeShellScriptBin "sudo-with-vars" ''sudo ${shellVars} $@'';
          in
          pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.riseup-vpn-configurator ];

            # buildInputs = [ pythonEnv ];
            packages = with pkgs; [
              pylyzer
              ruff
              sudoWithVars
            ];

            shellHook = ''
              echo ${shellVars}
              ${exportShellVars}
            '';
          };

        # Shell for poetry.
        #
        #     nix develop .#poetry
        #
        # Use this shell for changes to pyproject.toml and poetry.lock.
        devShells.poetry = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      });
}
