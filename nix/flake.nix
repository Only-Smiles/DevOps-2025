{
    description = "A flake for ruby project";

    inputs = { 
        nixpkgs.url = "nixpkgs/nixos-unstable"; 

        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils, ... }:
        flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            packageOverrides = pkgs.callPackage ./python-packages.nix { };
            python = pkgs.python313.override { inherit packageOverrides; };

        in
            {
            devShells.default = pkgs.mkShell {
                buildInputs = with pkgs; [
                    git
                    ruby_3_4
                    bundler
                    libpq
                ];
                packages = [
                    (pkgs.python313.withPackages (p: with p; [
                        requests
                        python-dotenv
                        pytest
                        psycopg
                    ]))
                ];


                shellHook = ''
          export GEM_HOME=$PWD/.bundle
          export PATH=$GEM_HOME/bin:$PATH
          bundle install # --gemfile ../Gemfile
          '';
            };

        });

}
