local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.color_scheme = "OneDark (base16)"
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
-- config.font = wezterm.font('MesloLGS NF')
config.window_frame = { font = wezterm.font({ family = "Noto Sans", weight = "Regular" }) }
-- config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- match the URL with a PORT
-- table.insert(config.hyperlink_rules,    { --     regex = "\\b\\w+://(?:[\\w.-]+):\\d+\\S*\\b", --     format = "$0", -- })

config.use_dead_keys = false
config.scrollback_lines = 5000
config.disable_default_key_bindings = true -- config.enable_kitty_keyboard = true -- config.enable_csi_u_key_encoding = false
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "q", mods = "CMD", action = act.QuitApplication },
	{ key = "l", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "h", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "Enter", mods = "CMD", action = act.ActivateCopyMode },
	{ key = "R", mods = "SHIFT|CMD", action = act.ReloadConfiguration },
	{
		key = "R",
		mods = "CTRL|SHIFT",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "+", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },
	{ key = "C", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
	{ key = "N", mods = "SHIFT|CTRL", action = act.SpawnWindow },
	{
		key = "U",
		mods = "SHIFT|CTRL",
		action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
	},
	{ key = "v", mods = "SHIFT|CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "LeftArrow", mods = "SHIFT|CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "SHIFT|CMD", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "SHIFT|CMD", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "SHIFT|CMD", action = act.ActivatePaneDirection("Down") },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "+", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Up") },
	{ key = "h", mods = "CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Right") },
	{ key = "y", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{
		key = "t",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewTab({ cwd = "~" }),
	},
	{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "b", mods = "LEADER|CTRL", action = act.SendString("\x02") },
	{ key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "p", mods = "LEADER", action = act.PasteFrom("PrimarySelection") },
	{
		key = "k",
		mods = "CTRL|ALT",
		action = act.Multiple({
			act.ClearScrollback("ScrollbackAndViewport"),
			act.SendKey({ key = "L", mods = "CTRL" }),
		}),
	},
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = "<", mods = "ALT", action = act.MoveTabRelative(-1) },
	{ key = ">", mods = "SHIFT|ALT", action = act.MoveTabRelative(1) },
	-- Zoom current pane
	{ key = "m", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	-- rotate panes
	{ mods = "LEADER", key = "Space", action = wezterm.action.RotatePanes("Clockwise") },
	-- show the pane selection mode, but have it swap the active and selected panes
	{
		mods = "LEADER",
		key = "0",
		action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }),
	},
}

config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
-- Maximize window on startup
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- Import tab-bar module
local tab_bar = require("plugins.tab-bar")
tab_bar.apply_to_config(config, {
	position = "bottom",
	max_width = 40,
	clock = {
		enabled = false,
		format = "",
	},
	dividers = "slant_right",
})

config.inactive_pane_hsb = {
	saturation = 0.1,
	-- hue = 0.9,
	brightness = 0.4,
}

return config
