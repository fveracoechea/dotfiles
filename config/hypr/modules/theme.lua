local theme = {}

function theme.apply(data)
  local function rgb(color)
    return "rgb(" .. color:sub(2):lower() .. ")"
  end

  hl.config {
    general = {
      ["col.active_border"] = { colors = { rgb(data.theme.blue), rgb(data.theme.flamingo) }, angle = 90 },
      ["col.inactive_border"] = rgb(data.theme.surface2),
    },
  }
end

return theme
