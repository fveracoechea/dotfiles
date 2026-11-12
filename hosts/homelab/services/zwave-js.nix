{ ... }: {
  services.zwave-js = {
    enable = true;
    serialPort = "/dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_00D9B441-if01-port0";
    secretsConfigFile = "/var/lib/zwave-js/secrets.json";
  };
}
