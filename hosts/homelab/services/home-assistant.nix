{ ... }: {
  hardware.bluetooth.enable = true;
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "sun"
      "mobile_app"
      "bluetooth"
      "timer"
      "local_file"
      "local_todo"
      "local_calendar"
      "generic_thermostat"
      "generic_hygrostat"
      "mold_indicator"
      "history_stats"
      "google_translate"
      "radio_browser"
      "reolink"
      "profiler"
      "ipp"
      "tplink"
      "tplink_tapo"
      "wake_on_lan"
      "webostv"
      "zwave_js"
      "zha"
    ];
    extraPackages =
      ps: with ps; [
        gtts
        radios
        pyswitchbot
        ibeacon-ble
        govee-ble
        inkbird-ble
        bthome-ble
        xiaomi-ble
        qingping-ble
        airthings-ble
        thermobeacon-ble
        thermopro-ble
        ruuvitag-ble
        sensorpush-ble
        sensirion-ble
      ];
    config = {
      default_config = { };
      homeassistant.internal_url = "http://10.0.0.2:8123";
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
  };
  systemd.services.home-assistant.serviceConfig.AmbientCapabilities = [
    "CAP_NET_ADMIN"
    "CAP_NET_RAW"
  ];

  networking.firewall.interfaces.enp8s0.allowedTCPPorts = [ 8123 ];

  services.caddy.virtualHosts."home.veracoechea.com".extraConfig = ''
    tls /var/lib/acme/veracoechea.com/fullchain.pem /var/lib/acme/veracoechea.com/key.pem
    reverse_proxy 127.0.0.1:8123
  '';
}
