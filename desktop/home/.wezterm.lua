local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Gruvbox dark, medium (base16)"
config.window_background_opacity = 1
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.scrollback_lines = 3500
config.enable_scroll_bar = true
config.disable_default_key_bindings = true

config.keys = {
	{ key = "y", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "Enter", mods = "ALT", action = act.SpawnTab("DefaultDomain") },
	{ key = "c", mods = "ALT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "h", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "ALT", action = act.ActivateTabRelative(1) },
	{ key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },
	{ key = "h", mods = "ALT|CTRL", action = act.MoveTabRelative(-1) },
	{ key = "LeftArrow", mods = "ALT|CTRL", action = act.MoveTabRelative(-1) },
	{ key = "l", mods = "ALT|CTRL", action = act.MoveTabRelative(1) },
	{ key = "RightArrow", mods = "ALT|CTRL", action = act.MoveTabRelative(1) },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "C", mods = "CTRL", action = act.CopyTo("ClipboardAndPrimarySelection") },
	{ key = "k", mods = "ALT", action = act.ScrollByPage(-1) },
	{ key = "j", mods = "ALT", action = act.ScrollByPage(1) },
}

for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "ALT",
		action = act.ActivateTab(i - 1),
	})
end

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = "Middle" } },
		mods = "NONE",
		action = act.PasteFrom("PrimarySelection"),
	},
}

return config
