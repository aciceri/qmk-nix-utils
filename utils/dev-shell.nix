{ pkgs
, qmk-firmware-source
, keyboard-name
, firmware-path
, qmk-home ? ".qmk_firmware"
, avr ? true
, arm ? true
, teensy ? true
}:

let
  shell-hook-pre-message = ''
    Generating ${qmk-home}, please wait...
  '';

  shell-hook-post-message = ''
    
    In this development shell you have access to qmk CLI to work with ${keyboard-name}'s firmware.
    The \$QMK_HOME is set to local ${qmk-home}, this directory is automatically recreated every time you enter this shell.
    The local ./src folder links to \$QMK_HOME/keyboards/${keyboard-name}, this mechanism is necessary to keep things faster.

    Although you can use directly use qmk, building and flashing the firmware with nix is recommended.
    To build the firmware: nix build
    To flash the firmware: nix run .#flash

  '';
in

with pkgs;
let
  avrlibc = pkgsCross.avr.libcCross;

  avr_incflags = [
    "-isystem ${avrlibc}/avr/include"
    "-B${avrlibc}/avr/lib/avr5"
    "-L${avrlibc}/avr/lib/avr5"
    "-B${avrlibc}/avr/lib/avr35"
    "-L${avrlibc}/avr/lib/avr35"
    "-B${avrlibc}/avr/lib/avr51"
    "-L${avrlibc}/avr/lib/avr51"
  ];

  customQmk = pkgs.qmk.overrideAttrs (oldAttrs: {
    dontWrapPythonPrograms = true;
  });
in
mkShell {
  name = "qmk-firmware";

  buildInputs = [
    clang-tools
    dfu-programmer
    dfu-util
    git
    customQmk

  ]
  ++ lib.optional avr [
    pkgsCross.avr.buildPackages.binutils
    pkgsCross.avr.buildPackages.gcc8
    avrlibc
    avrdude
  ]
  ++ lib.optional arm [ gcc-arm-embedded ]
  ++ lib.optional teensy [ teensy-loader-cli ];

  AVR_CFLAGS = lib.optional avr avr_incflags;
  AVR_ASFLAGS = lib.optional avr avr_incflags;

  SKIP_GIT = true;
  SKIP_VERSION = true;

  QMK_HOME = qmk-home;

  shellHook = ''
    echo "${shell-hook-pre-message}"

    chmod --silent -R u+w $QMK_HOME
    rm -rf $QMK_HOME
    mkdir -p $QMK_HOME
    
    cp -rn ${qmk-firmware-source}/* $QMK_HOME
    chmod -R 755 $QMK_HOME
    cd $QMK_HOME/keyboards
    ln -sf ../../src ${keyboard-name}
    cd ../..

    # Prevent the avr-gcc wrapper from picking up host GCC flags
    # like -iframework, which is problematic on Darwin
    unset NIX_CFLAGS_COMPILE_FOR_TARGET

    echo "${shell-hook-post-message}"
  '';
}
