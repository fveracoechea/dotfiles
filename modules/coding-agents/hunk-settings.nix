configHome: {
  theme = "catppuccin-mocha";
  mode = "stack";
  line_numbers = true;
  warp_lines = false;
  transparent_background = true;
  hunk_headers = false;
  # Hunk's automatic discovery skips symlinked extension directories.
  extensions.paths = ["${configHome}/hunk/extensions/hunk-gh"];
}
