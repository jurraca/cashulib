{
  description = "An Elixir library for the Cashu ecash protocol.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-24.05;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system ; };
        beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_27;
        elixir = beamPackages.elixir_1_16;
        devShell = import ./shell.nix { inherit pkgs beamPackages; };

        cashex = let
            lib = pkgs.lib;
            mixNixDeps = import ./deps.nix {inherit lib beamPackages;};
          in beamPackages.mixRelease {
            pname = "cashex";
            src = ./.;
            version = "0.1.0";

            inherit mixNixDeps;

            buildInputs = [ elixir ];
          };
      in
      {
        devShells.default = devShell;
        packages.default = cashex;
      }
    );
}

