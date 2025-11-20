{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  apple-sdk_15,
  alsa-oss,
}:

stdenv.mkDerivation rec {
  pname = "sbagen";
  version = "1.4.5";

  src = fetchurl {
    url = "https://uazu.net/sbagen/sbagen-${version}.tgz";
    sha256 = "1r10ya3i58bad2lsa064dzp5jk4v4zdsbx42nbkadfpii47mvc02";
  };

  postPatch = ''
    patchShebangs scripts mk mk-*

    substituteInPlace mk \
      --replace "-DT_LINUX -Wall -m32 -O3 -s -lm -lpthread" "-DT_LINUX -Wall -O3 -s -lm -lpthread"

    rm -rf libs

    substituteInPlace mk-macosx \
      --replace 'CFLAGS="-m32 -mmacosx-version-min=10.4 -DT_MACOSX"' 'CFLAGS="-mmacosx-version-min=10.4 -DT_MACOSX"' \
      --replace '-I/System/Library/Frameworks/Carbon.framework/Headers' '-I$SDKROOT/System/Library/Frameworks/Carbon.framework/Headers'
  '';

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux makeWrapper;

  buildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk_15 ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-oss ];

  buildPhase = if stdenv.hostPlatform.isDarwin then "./mk-macosx" else "./mk";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/sbagen/doc

    cp sbagen $out/bin/sbagen
    cp -r --target-directory=$out/share/sbagen examples scripts river1.ogg river2.ogg
    cp --target-directory=$out/share/sbagen/doc README.txt SBAGEN.txt theory.txt theory2.txt wave.txt holosync.txt focus.txt TODO.txt

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/sbagen \
      --prefix LD_PRELOAD : ${alsa-oss}/lib/libaoss.so
  '';

  meta = {
    description = "Binaural sound generator";
    homepage = "http://uazu.net/sbagen";
    license = lib.licenses.gpl2;
    mainProgram = "sbagen";
    platforms = lib.platforms.unix;
  };
}
