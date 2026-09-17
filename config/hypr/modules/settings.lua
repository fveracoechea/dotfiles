local settings = {}

function settings.apply(data)
  local declared_outputs = {}
  for _, spec in ipairs(data.monitors) do
    local fields = {}
    for field in (spec .. ","):gmatch "(.-)," do
      fields[#fields + 1] = field:match "^%s*(.-)%s*$"
    end
    local monitor = { output = fields[1] }
    if fields[2] == "disable" or fields[2] == "disabled" then
      monitor.disabled = true
    elseif fields[2] == "transform" then
      monitor.transform = assert(tonumber(fields[3]), "invalid monitor transform")
      assert(
        monitor.transform % 1 == 0 and monitor.transform >= 0 and monitor.transform <= 7,
        "invalid monitor transform"
      )
      if not declared_outputs[monitor.output] then
        monitor = nil
      end
    elseif fields[2] == "addreserved" then
      monitor.reserved = {
        top = assert(tonumber(fields[3]), "invalid reserved top"),
        bottom = assert(tonumber(fields[4]), "invalid reserved bottom"),
        left = assert(tonumber(fields[5]), "invalid reserved left"),
        right = assert(tonumber(fields[6]), "invalid reserved right"),
      }
      -- Legacy addreserved without an earlier output rule adds only a default rule.
      if not declared_outputs[monitor.output] then
        monitor.reserved = nil
      end
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
    if monitor then
      hl.monitor(monitor)
      declared_outputs[monitor.output] = true
    end
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
