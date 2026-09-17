local settings = {}

function settings.apply(data)
  for _, spec in ipairs(data.monitors) do
    local fields = {}
    for field in (spec .. ","):gmatch "(.-)," do
      fields[#fields + 1] = field:match "^%s*(.-)%s*$"
    end
    local monitor = { output = fields[1] }
    if fields[2] == "disable" or fields[2] == "disabled" then
      monitor.disabled = true
    else
      monitor.mode = fields[2]
      monitor.position = fields[3]
      monitor.scale = fields[4]
      local numeric = { bitdepth = true, transform = true, vrr = true, sdrbrightness = true, sdrsaturation = true }
      local strings = { mirror = true, cm = true, icc = true }
      for i = 5, #fields, 2 do
        local key, value = fields[i], fields[i + 1]
        assert(value, "monitor field needs a value: " .. key)
        assert(numeric[key] or strings[key], "unsupported monitor field: " .. key)
        monitor[key] = numeric[key] and assert(tonumber(value), "invalid monitor number: " .. value) or value
      end
    end
    hl.monitor(monitor)
  end

  hl.config {
    cursor = { enable_hyprcursor = false },
    misc = { vrr = 2, animate_manual_resizes = true, animate_mouse_windowdragging = true },
    general = {
      layout = "dwindle",
      border_size = 3,
      resize_on_border = true,
      gaps_in = 10,
      gaps_out = { top = 10, right = 18, bottom = 18, left = 18 },
    },
    layout = { single_window_aspect_ratio = "16 9" },
    dwindle = { preserve_split = true, force_split = 2 },
    decoration = { rounding = 8, blur = { enabled = true } },
    master = { allow_small_split = true, mfact = 0.32, new_on_top = false },
    binds = { drag_threshold = 10, allow_workspace_cycles = true },
  }

  for workspace = 1, 5 do
    hl.workspace_rule { workspace = tostring(workspace), persistent = true }
  end
end

return settings
