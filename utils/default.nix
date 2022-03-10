{ pkgs, qmk-firmware-default-source, ... }:
{ firmware-path
, keyboard-name
, keymap-name
, extra-build-inputs ? [ ]
, qmk-firmware-source ? qmk-firmware-default-source
, avr ? true
, arm ? true
, teensy ? true
}:
with pkgs.stdenv;
let

  qmk-with-keyboard-src = mkDerivation {
    name = "qmk-with-keyboard-src";
    src = qmk-firmware-source;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir "$out"
      cp -r "$src"/* "$out"
      KEYBOARDS_DIR=$out/keyboards
      chmod +w $KEYBOARDS_DIR
      cp -r ${firmware-path} $KEYBOARDS_DIR/${keyboard-name}
      chmod -w $KEYBOARDS_DIR
    '';
  };

  hex = mkDerivation {
    name = "hex";
    nativeBuildInputs = with pkgs; extra-build-inputs ++ [
      qmk
    ];
    src = qmk-with-keyboard-src;

    buildPhase = ''
      SKIP_GIT=true SKIP_VERSION=true \
          qmk compile -kb ${keyboard-name} -km ${keymap-name}
    '';
    installPhase = ''
      mkdir $out
      cp ${keyboard-name}_${keymap-name}.hex $out
    '';
  };

  dev-shell = import ./dev-shell.nix {
    inherit pkgs qmk-firmware-source keyboard-name firmware-path avr arm teensy;
  };

in
{
  inherit qmk-src hex dev-shell;
}

