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
                export KEYCLOAKIFY_USE_DEFAULT_MAVEN_REPO=false

                pnpm build-keycloak-theme || true
              '';

              installPhase = ''
                mkdir -p $out

                # Copy from where keycloakify actually stores the Maven repo
                if [ -d "node_modules/.cache/keycloakify/.m2" ]; then
                  cp -r node_modules/.cache/keycloakify/.m2 $out/.m2
                  find $out/.m2 -name '*.lastUpdated' -delete || true
                  find $out/.m2 -name '_remote.repositories' -delete || true
                else
                  echo "ERROR: Maven repo not found at node_modules/.cache/keycloakify/.m2"
                  exit 1
                fi
              '';

              outputHashMode = "recursive";
              outputHashAlgo = "sha256";
              outputHash = pkgs.lib.fakeHash;
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
              # Copy the pre-fetched Maven repo to where keycloakify expects it
              mkdir -p node_modules/.cache/keycloakify
              cp -r ${keycloakifyMavenRepo}/.m2 node_modules/.cache/keycloakify/.m2

              export KEYCLOAKIFY_USE_DEFAULT_MAVEN_REPO=false
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
