-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'AdventureTime'
config.color_scheme = 'Gruvbox dark, medium (base16)'
config.enable_scroll_bar = true

-- and finally, return the configuration to wezterm

local wezterm = require 'wezterm';

local act = wezterm.action
config.disable_default_key_bindings = true
-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500
config.enable_scroll_bar = true

local wezterm = require 'wezterm'
local act = wezterm.action

config.keys = {
  { key = 'V', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
  { key = 'V', mods = 'CTRL', action = act.PasteFrom 'PrimarySelection' },

  { key = 'Enter', mods = 'ALT', action = act.SpawnTab 'DefaultDomain' },
  { key = 'c', mods = 'ALT', action = wezterm.action.CloseCurrentTab{ confirm = true },},

  { key = 'h', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = 'l', mods = 'ALT', action = act.ActivateTabRelative(1) },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivateTabRelative(1) },

  { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
  {
    key = 'C',
    mods = 'CTRL',
    action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
  },
  { key = 'k', mods = 'ALT', action = act.ScrollByPage(-1) },
  { key = 'j', mods = 'ALT', action = act.ScrollByPage(1) },
}

for i = 1, 8 do
  -- CTRL+ALT + number to move to that position
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'ALT',
    action = wezterm.action.ActivateTab(i - 1),
  })
end

config.mouse_bindings = {
  -- Right click sends "woot" to the terminal
--  {
--    event = { Down = { streak = 1, button = 'Right' } },
--    mods = 'NONE',
--    action = act.SendString 'woot',
--  },

  -- Change the default click behavior so that it only selects
  -- text and doesn't open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },

  -- and make CTRL-Click open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- NOTE that binding only the 'Up' event can give unexpected behaviors.
  -- Read more below on the gotcha of binding an 'Up' event only.
}


return config
