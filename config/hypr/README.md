# Native Hyprland configuration

Home Manager installs these files from the Nix store through `extraLuaFiles`.
Only `entry.lua` autoloads. It validates `dotfiles/hyprland.json` before it
applies settings, environment, bindings, window rules, and Theme values.
The generated `hyprland.lua` owns the upstream systemd session hooks and loader.
Its final loader line requires `lifecycle.lua` after those hooks. This keeps
the systemd environment/target command ahead of Ultrashell in startup launch
order. Both commands spawn asynchronously, as they did in the captured config;
this order does not guarantee that target setup completes before Ultrashell.
The user approved the upstream Lua shutdown hook's synchronous target stop
and conditional 0.1-second wait as the one shutdown parity exception. See
`checks/hyprland/api.md` for source evidence and the exact checked command.

The bridge loader comes from `checks/hyprland/bridge.lua` at repository commit `f04670b`.
Both copies accept the shipped empty monitor array while rejecting JSON null and all objects, including empty objects.
The decoder tracks array/object types in a private weak-key map, and the bridge requires `json.is_array(monitors)`.
The entry returns an explicit success value because Hyprland catches module errors and caches an empty table.
User startup registers only after that success value; upstream session hooks remain Home Manager-owned.

`lib/json.lua` started from the reviewed strict decoder in `checks/hyprland/lib/json.lua` at the same commit.
The production and reference copies remain identical, including the container-type extension.
Its upstream source is
[rxi/json.lua v0.1.2](https://github.com/rxi/json.lua/blob/d1e3b0f5d0f3d3493c7dadd0bb54135507fcebd7/json.lua),
revision `d1e3b0f5d0f3d3493c7dadd0bb54135507fcebd7`. The MIT license stays in
the file. The reviewed local changes preserve JSON null, enforce JSON number
and comma grammar, validate escapes, UTF-8 and surrogate pairs, and reject
duplicate keys and non-finite numbers.
The container-type extension leaves decoded fields and metatables unchanged and preserves array/object types on encoding.

The checks and source-verified API contract are in `checks/hyprland/`.
