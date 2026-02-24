{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  openssl,
  nodejs_20,
}:

let
  version = "0.4.1";

  srcWithLock = runCommand "portless-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/portless/-/portless-${version}.tgz";
        hash = "sha256-0Xjf7fgBoBu1OFcl+GakLHCX+QpwJfQgpe/FGRKa9OY=";
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in

buildNpmPackage {
  pname = "portless";
  inherit version;

  src = srcWithLock;

  npmDepsHash = "sha256-sFswfaVLupYx220aIHPYxrFw6N2H8ZjfyQu+JCaqmKg=";

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
