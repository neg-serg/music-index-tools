{
  description = "music-index-tools — build and query the MERT music similarity index";

  # Minimal on purpose: the host flake consumes `packages.<system>.default` and
  # makes this input follow its nixpkgs pin, so the binary is built against the
  # same nixpkgs as the system that runs it.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        music-index-tools = self.packages.${system}.default;
      });

      # Both self-checks run on the deterministic SHAKE-128 stub embedder:
      # no torch, no model, no venv and no music library are needed. They cover
      # the scan/cache/npy/index/ranking pipeline end to end.
      checks = forAllSystems (system: {
        selftest =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            pkg = self.packages.${system}.default;
          in
          pkgs.runCommand "music-index-tools-selftest" { } ''
            ${pkg}/bin/music-index --selftest
            ${pkg}/bin/music-similar --selftest
            touch "$out"
          '';
      });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            cargo
            rustc
            clippy
            rustfmt
            rust-analyzer
          ];
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
