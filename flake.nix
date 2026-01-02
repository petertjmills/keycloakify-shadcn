{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
        pkgs = nixpkgs.legacyPackages.${system};

        pname = "keycloakify-shadcn";
        version = "0.0.1";
        src = ./.;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          inherit pname version src;

          nativeBuildInputs = [

          ];

          installPhase = ''
            mkdir -p $out
            cp -r dist_keycloak $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs
            pkgs.pnpm
            pkgs.maven
          ];

          shellHook = ''
            export KEYCLOAKIFY_USE_DEFAULT_MAVEN_REPO=false
          '';
        };
      }
    );
}
