local windowrules = {}

function windowrules.apply()
  hl.window_rule { match = { tag = "floating-window" }, float = true }
  hl.window_rule { match = { tag = "floating-window" }, center = true }
  hl.window_rule { match = { tag = "floating-window" }, size = "1024 768" }
  hl.window_rule {
    match = { class = "(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|TUI.float|imv|mpv)" },
    tag = "+floating-window",
  }
  hl.window_rule {
    match = {
      class = "(xdg-desktop-portal-gtk|DesktopEditors|org.gnome.Nautilus)",
      title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag = "+floating-window",
  }
  hl.window_rule { match = { class = "org.gnome.Calculator" }, float = true }
  hl.window_rule { match = { fullscreen = "1" }, border_size = 0 }
  hl.window_rule { match = { class = ".*" }, idle_inhibit = "fullscreen" }
  hl.window_rule { match = { class = ".*" }, suppress_event = "maximize" }
end

return windowrules
