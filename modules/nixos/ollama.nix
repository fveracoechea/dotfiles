{
  pkgs,
  lib,
  config,
  ...
}: let
  ollamaPort = 11434;
in {
  options.dotfiles.ollama.enable = lib.mkEnableOption "Ollama + Open WebUI";

  config = lib.mkIf config.dotfiles.ollama.enable {
    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        port = ollamaPort;
        loadModels = [
          "mistral:latest"
          "mistral-nemo:latest"
          "deepseek-r1:14b"
          "qwen3:14b"
          "qwen3-coder:latest"
          "devstral:latest"
        ];
        environmentVariables = {
          OLLAMA_KEEP_ALIVE = "15m";
          OLLAMA_NUM_PARALLEL = "2";
          CUDA_VISIBLE_DEVICES = "0";
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_CONTEXT_LENGTH = "16384";
        };
      };

      open-webui = {
        enable = true;
        port = 8888;
        host = "127.0.0.1";
        stateDir = "/var/lib/open-webui";
        environment = {
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          ANONYMIZED_TELEMETRY = "False";
          DATA_DIR = "~/.local/state/open-webui";
          OLLAMA_BASE_URL = "http://127.0.0.1:${toString ollamaPort}";
        };
      };
    };
  };
}
