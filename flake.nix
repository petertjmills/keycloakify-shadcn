{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      ...
    }@inputs:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "keycloakify-shadcn";
          version = "0.0.1";

          src = ./.;

          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.typescript
            pkgs.pnpm
            pkgs.pnpm.configHook
            pkgs.maven
          ];
          pnpmDeps = pkgs.pnpm.fetchDeps {
            inherit (self.packages.${system}.default) pname version src;
            hash = "sha256-+vmB6EAeHQZ+6zATcTZZWGB3F0NIHa0AomC6ALDT/cg=";
          };

          installPhase = ''
            mkdir -p $out/bin
            pnpm build-keycloak-theme
            cp -r dist_keycloak $out/
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs
            pkgs.pnpm
            pkgs.maven
          ];

          shellHook = '''';
        };
      }
    );
}
