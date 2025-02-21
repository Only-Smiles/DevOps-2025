{
    description = "A flake for ruby project";

    inputs = { nixpkgs.url = "nixpkgs/nixos-unstable"; };

    outputs = { self, nixpkgs, ... }:
        let
            system = "aarch64-darwin";
            pkgs = nixpkgs.legacyPackages.${system};
            packageOverrides = pkgs.callPackage ./python-packages.nix { };
            python = pkgs.python3.override { inherit packageOverrides; };

        in
            {
            devShells.${system}.default = pkgs.mkShell {
                buildInputs = with pkgs; [
                    git
                    ruby_3_4
                    bundler
                ];
                packages = [
                    (pkgs.python313.withPackages (p: with p; [
                        requests
                        python-dotenv
                        pytest
                    ]))
                ];


                shellHook = ''
          if [ ! -d .bundle ]; then
          bundle install --gemfile ../gemfile
          fi
          '';
            };

        };

}
