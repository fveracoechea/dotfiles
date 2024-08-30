{
  pkgs,
  lib,
  ...
}: {
  programs.nix-ld.enable = true;

  environment.variables = with pkgs; {
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
      stdenv.cc.cc
      openssl
      nss
      gcc
    ];
    # NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
  };

  # Add any missing dynamic libraries for unpackaged programs
  # here, NOT in environment.systemPackages
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    fuse3
    gdk-pixbuf
    glib
    icu
    libGL
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libunwind
    libusb1
    libuuid
    libxkbcommon
    libxml2
    rustc
    cargo
    nspr
    nss
    openssl
    pango
    pipewire
    stdenv.cc.cc
    gcc
    libgcc
    systemd
    vulkan-loader
    zlib
  ];
}
