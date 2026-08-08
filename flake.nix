{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        beamPackages = with pkgs.beam29Packages; [
          elixir_1_20
          erlang
          (elixir-ls.override {
            elixir = pkgs.beam29Packages.elixir_1_20;
          })
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              direnv
              just
              nodejs_26
            ]
            ++ beamPackages;

          shellHook = ''
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex

            mix deps.get
            eval "$(direnv hook bash)"
            direnv allow
          '';
        };
      }
    );
}
