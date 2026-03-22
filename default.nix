{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  jq,
  openssl,
  nodejs_20,
}:

let
  version = "0.7.2";

  srcWithLock = runCommand "portless-src-with-lock" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/portless/-/portless-${version}.tgz";
        hash = "sha256-zfPyhJT/WlFkZ+198p2j7Xl2Znxpj3VRR+6zZX0/dK4=";
      }
    } -C $out --strip-components=1
    # Strip devDependencies so npm ci doesn't try to resolve them
    jq 'del(.devDependencies)' $out/package.json > $out/package.json.tmp
    mv $out/package.json.tmp $out/package.json
    cp ${./package-lock.json} $out/package-lock.json
  '';
in

buildNpmPackage {
  pname = "portless";
  inherit version;

  src = srcWithLock;

  npmDepsHash = "sha256-ngDK/6yJmQ5uzqDk//Pa7DqAOQIarTUcYU7OI8Hkc9M=";

  dontNpmBuild = true;
  nodejs = nodejs_20;

  postInstall = ''
    wrapProgram $out/bin/portless \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}
  '';

  meta = with lib; {
    description = "Replace port numbers with stable, named .localhost URLs";
    homepage = "https://github.com/vercel-labs/portless";
    license = licenses.asl20;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "portless";
  };
}
