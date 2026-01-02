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
        packages.default =
          let
            # -------------------------------
            # Phase 1: Fixed-output Maven repo
            # -------------------------------
            keycloakifyMavenRepo = pkgs.stdenv.mkDerivation {
              pname = "${pname}-maven-repo";
              version = "1";

              inherit src;

              nativeBuildInputs = [
                pkgs.nodejs
                pkgs.typescript
                pkgs.pnpm
                pkgs.pnpm.configHook
                pkgs.maven
              ];

              pnpmDeps = pkgs.pnpm.fetchDeps {
                inherit pname version src;
                hash = "sha256-+vmB6EAeHQZ+6zATcTZZWGB3F0NIHa0AomC6ALDT/cg=";
              };

              buildPhase = ''
                mkdir -p $out

                export KEYCLOAKIFY_USE_DEFAULT_MAVEN_REPO=false
                export MAVEN_OPTS="-Dmaven.repo.local=$out/.m2"

                pnpm build-keycloak-theme
              '';

              installPhase = ''
                if [ -d "$out/.m2" ]; then
                  find $out/.m2 -name '*.lastUpdated' -delete || true
                  find $out/.m2 -name '_remote.repositories' -delete || true
                fi
              '';

              outputHashMode = "recursive";
              outputHashAlgo = "sha256";
              outputHash = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
            };
          in
          # -------------------------------
          # Phase 2: Final offline build
          # -------------------------------
          pkgs.stdenv.mkDerivation {
            inherit pname version src;

            nativeBuildInputs = [
              pkgs.nodejs
              pkgs.typescript
              pkgs.pnpm
              pkgs.pnpm.configHook
              pkgs.maven
            ];

            buildInputs = [
              keycloakifyMavenRepo
            ];

            pnpmDeps = pkgs.pnpm.fetchDeps {
              inherit pname version src;
              hash = "sha256-+vmB6EAeHQZ+6zATcTZZWGB3F0NIHa0AomC6ALDT/cg=";
            };

            buildPhase = ''
              export KEYCLOAKIFY_USE_DEFAULT_MAVEN_REPO=false
              export MAVEN_OPTS="-Dmaven.repo.local=${keycloakifyMavenRepo}/.m2"
              export MAVEN_ARGS="-o -nsu"

              pnpm build-keycloak-theme
            '';

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
