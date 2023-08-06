{ pkgs, qmk-firmware-default-source, ... }:
{ src
, keyboard-name
, keymap-name
, flash-script ? null
, extra-build-inputs ? [ ]
, qmk-firmware-source ? qmk-firmware-default-source
, type ? "keyboard"
, avr ? true
, arm ? true
, teensy ? true
}:
with pkgs.stdenv;
let
  firmware-path = src;

  qmk-with-keyboard-src = mkDerivation {
    name = "qmk-with-keyboard-src";
    src = qmk-firmware-source;
    phases = [ "installPhase" ];

    installPhase = let
      target_dir = if type == "keyboard" then
        "$out/keyboards"
      else if type == "keymap" then
        "$out/keyboards/${keyboard-name}/keymaps"
      else throw "The only values valid for type are 'keyboard' and 'keymap'.";
    in ''
      mkdir "$out"
      cp -r "$src"/* "$out"
      chmod +w ${target_dir}
      cp -r ${firmware-path} ${target_dir}/${keymap-name}
      chmod -w ${target_dir}
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
      cp -r .build/* $out
    '';
  };

  flasher =
    if builtins.isNull flash-script
    then builtins.throw "You need to pass a \"flash-command\" to \"utils-factory\""
    else
      pkgs.writeShellScriptBin "flasher" ''
        HEX_FILE=$(find ${hex}/ -type f -name "*.hex" | head -n 1)
        
        ${flash-script}
      '';

  dev-shell = import ./dev-shell.nix {
    inherit pkgs qmk-firmware-source keyboard-name firmware-path avr arm teensy;
  };

in
{
  inherit hex flasher dev-shell;
}

