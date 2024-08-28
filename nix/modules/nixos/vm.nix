{
  # VM only options
  virtualisation.qemu.options = [
    "-device virtio-vga-gl"
    "-display sdl,gl=on,show-cursor=off"
    "-audio pa,model=hda"
  ];

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
