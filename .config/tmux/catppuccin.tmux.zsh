set -g @catppuccin_window_left_separator "█"
set -g @catppuccin_window_right_separator "█ "
set -g @catppuccin_window_number_position "right"
set -g @catppuccin_window_middle_separator "  █"

set -g @catppuccin_window_default_fill "number"
set -g @catppuccin_window_default_text "#W"

set -g @catppuccin_window_current_fill "number"
# set -g @catppuccin_window_current_text "#{pane_current_path}"
set -g @catppuccin_window_current_text "#[bold]#(echo #{pane_current_path} | sed 's#$HOME#~#g')"
# set -g @catppuccin_window_current_text "#[underscore]#{?#{==:#{window_panes},1},,+}#[bold]#W#[nobold]:#{=|-24|…;s|$HOME|~|:pane_current_path}"

set -g @catppuccin_status_modules_right "session application cpu uptime clima"
set -g @catppuccin_status_left_separator  " "
set -g @catppuccin_status_right_separator ""
set -g @catppuccin_status_fill "icon"
set -g @catppuccin_status_connect_separator "no"


set -g @clima_unit imperial
set -g @clima_use_nerd_font 1
