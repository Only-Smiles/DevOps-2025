{
  description = "A flake for ruby project";

  inputs = { nixpkgs.url = "nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          ruby_3_4
          bundler
        ];

        shellHook = ''
          if [ ! -d .bundle ]; then
          bundle install --gemfile ../gemfile
          fi
        '';
      };

    };

}
