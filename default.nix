{
  lib,
  stdenvNoCC,
  fetchurl,
  jq,
  makeWrapper,
  openssl,
  nodejs_20,
}:

let
  pname = "portless";
  version = "0.15.6";
  src = fetchurl {
    url = "https://registry.npmjs.org/portless/-/portless-${version}.tgz";
    hash = "sha256-SPFeXWPEd4RTTdletSAefmWM5D6uG3q5YNNLbWe5VIo=";
  };
in

stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    jq
    makeWrapper
  ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    packageOut="$out/lib/node_modules/${pname}"
    mkdir -p "$packageOut"
    tar -xzf "$src" -C "$packageOut" --strip-components=1

    binPath="$(jq -r '.bin.portless' "$packageOut/package.json")"
    if [ "$binPath" = "null" ]; then
      echo "portless tarball is missing a CLI entrypoint"
      exit 1
    fi

    mkdir -p "$out/bin"
    makeWrapper ${nodejs_20}/bin/node "$out/bin/portless" \
      --add-flags "$packageOut/''${binPath#./}" \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}

    runHook postInstall
  '';

  passthru.nodejs = nodejs_20;

  meta = with lib; {
    description = "Replace port numbers with stable, named .localhost URLs";
    homepage = "https://github.com/vercel-labs/portless";
    license = licenses.asl20;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "portless";
  };
}
