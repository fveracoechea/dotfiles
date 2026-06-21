{lib, config, ...}: {
  options.dotfiles.desktop-entries.enable = lib.mkEnableOption "custom XDG desktop entries";

  config = lib.mkIf config.dotfiles.desktop-entries.enable {
    xdg.desktopEntries = {
      "youtube-webapp" = {
        name = "YouTube (Web App)";
        exec = " google-chrome-stable --app=https://www.youtube.com";
        categories = ["Network" "WebBrowser"];
        mimeType = ["x-scheme-handler/youtube" "text/html" "text/xml"];
        icon = ./icons/youtube.svg;
      };
      "github-webapp" = {
        name = "GitHub (Web App)";
        exec = "google-chrome-stable --app=https://github.com";
        categories = ["Network" "WebBrowser"];
        mimeType = ["text/html" "text/xml"];
        icon = ./icons/github.svg;
      };
      "zoom-webapp" = {
        name = "Zoom (Web App)";
        exec = "google-chrome-stable --app=https://app.zoom.us/wc/home";
        categories = ["Network" "WebBrowser"];
        mimeType = ["text/html" "text/xml" "x-scheme-handler/zoommtg" "x-scheme-handler/zoomus"];
        icon = ./icons/zoom.svg;
      };
      "drizzle-webapp" = {
        name = "Drizzle Studio (Web App)";
        exec = "google-chrome-stable --app=https://local.drizzle.studio";
        categories = ["Network" "WebBrowser"];
        mimeType = ["text/html" "text/xml"];
        icon = ./icons/drizzle.svg;
      };
      "home-manager-appendix-webapp" = {
        name = "Home Manager Appendix (Web App)";
        exec = "google-chrome-stable --app=https://nix-community.github.io/home-manager/options.xhtml";
        categories = ["Network" "WebBrowser"];
        mimeType = ["text/html" "text/xml"];
        icon = ./icons/nixos.svg;
      };
    };
  };
}
