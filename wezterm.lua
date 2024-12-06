local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end
-- Determine if we're running on macOS
local function is_macos()
	return wezterm.target_triple:find("darwin") ~= nil
end

-- Get the appropriate modifier key based on OS
local function get_mod(mod)
	if mod == "SUPER" then
		return is_macos() and "CMD" or "CTRL"
	end
	return mod
end

-- Helper function to create keybindings with dynamic modifiers
local function key_bind(key, mods, action)
	local dynamic_mods = {}
	for mod in mods:gmatch("[^|]+") do
		table.insert(dynamic_mods, get_mod(mod))
	end
	return {
		key = key,
		mods = table.concat(dynamic_mods, "|"),
		action = action,
	}
end

if is_macos() then
	config.font_size = 16.0
	config.window_decorations = "RESIZE"
end

config.color_scheme = "OneDark (base16)"
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.window_frame = { font = wezterm.font({ family = "Noto Sans", weight = "Regular" }) }

config.use_dead_keys = false
config.scrollback_lines = 5000
config.disable_default_key_bindings = true
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- Keep CMD for both OS
	{ key = "q", mods = "CMD", action = act.QuitApplication },
	{ key = "l", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = "h", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "y", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Up") },
	{ key = "h", mods = "CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Right") },

	-- Dynamic modifiers (these changed between OS)
	key_bind("Enter", "SUPER", act.ActivateCopyMode),
	key_bind("+", "SUPER", act.IncreaseFontSize),
	key_bind("-", "SUPER", act.DecreaseFontSize),
	key_bind("0", "SUPER", act.ResetFontSize),
	key_bind("v", "SUPER", act.PasteFrom("Clipboard")),
	key_bind("LeftArrow", "SHIFT|SUPER", act.ActivatePaneDirection("Left")),
	key_bind("RightArrow", "SHIFT|SUPER", act.ActivatePaneDirection("Right")),
	key_bind("UpArrow", "SHIFT|SUPER", act.ActivatePaneDirection("Up")),
	key_bind("DownArrow", "SHIFT|SUPER", act.ActivatePaneDirection("Down")),

	-- Keep consistent across OS
	{ key = "C", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
	{ key = "N", mods = "SHIFT|CTRL", action = act.SpawnWindow },
	{
		key = "U",
		mods = "SHIFT|CTRL",
		action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
	},
	{ key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) },

	-- Leader based keys (same for both OS)
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "+", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{
		key = "t",
		mods = is_macos() and "CMD" or "LEADER",
		action = wezterm.action.SpawnCommandInNewTab({ cwd = "~" }),
	},
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "b", mods = "LEADER|CTRL", action = act.SendString("\x02") },
	{ key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "p", mods = "LEADER", action = act.PasteFrom("PrimarySelection") },
	{ key = "m", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{ key = "Space", mods = "LEADER", action = wezterm.action.RotatePanes("Clockwise") },
	{
		key = "0",
		mods = "LEADER",
		action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }),
	},

	-- Additional keys (same for both OS)
	{ key = "<", mods = "ALT", action = act.MoveTabRelative(-1) },
	{ key = ">", mods = "SHIFT|ALT", action = act.MoveTabRelative(1) },
	{
		key = "k",
		mods = "CTRL|ALT",
		action = act.Multiple({
			act.ClearScrollback("ScrollbackAndViewport"),
			act.SendKey({ key = "L", mods = "CTRL" }),
		}),
	},
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- Tab renaming
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
}

config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 5 }
-- Maximize window on startup
-- wezterm.on("gui-startup", function(cmd)
-- 	local _, _, window = mux.spawn_window(cmd or {})
-- 	window:gui_window():maximize()
-- end)

config.set_environment_variables = {
	PYTHON_PATH = "/usr/lib/python3/dist-packages:" .. (os.getenv("PYTHON_PATH") or ""),
	LD_LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:/usr/local/lib:" .. (os.getenv("LD_LIBRARY_PATH") or ""),
}

wezterm.on("gui-startup", function(cmd)
	local args = cmd and cmd.args or {}
	local env_vars = {
		PYTHON_PATH = "/usr/lib/python3/dist-packages:" .. (os.getenv("PYTHON_PATH") or ""),
		LD_LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:/usr/local/lib:" .. (os.getenv("LD_LIBRARY_PATH") or ""),
	}

	local _, papi, window = mux.spawn_window({
		workspace = "pvt",
		set_environment_variables = env_vars,
	})

	window:gui_window():maximize()

	if args[1] == "pvt" then
		papi:send_text("papi\n")
		papi:send_text("clear\n")

		local pweb = papi:split({
			direction = "Right",
			size = 0.5,
			cwd = wezterm.home_dir .. "/pvt-frontend",
			set_environment_variables = env_vars,
		})

		local papi_listener = papi:split({
			direction = "Bottom",
			size = 0.5,
		})
		papi_listener:send_text("putils\n")
		papi_listener:send_text("clear\n")

		local putils = pweb:split({
			direction = "Bottom",
			size = 0.5,
			set_environment_variables = env_vars,
		})
		putils:send_text("putils\n")
		putils:send_text("clear\n")

		if args[2] == "run" then
			papi:send_text("flask run\n")
			papi_listener:send_text("flask run_listener\n")
			pweb:send_text("pnpm dev\n")
			putils:send_text("python cloud_worker.py\n")
			-- else
			-- 	papi:send_text("flask run\n")
			-- 	papi_listener:send_text("flask run_listener\n")
			-- 	pweb:send_text("pnpm dev\n")
			-- 	putils:send_text("python cloud_worker.py\n")
		end
	end
end)

-- Import tab-bar module
local tab_bar = require("plugins.tab-bar")
tab_bar.apply_to_config(config, {
	position = "bottom",
	max_width = 40,
	clock = {
		enabled = false,
		-- format = "%H:%M:%S",
	},
	dividers = "slant_right",
})

config.inactive_pane_hsb = {
	saturation = 0.1,
	-- hue = 0.9,
	brightness = 0.4,
}

config.initial_rows = 40 -- Adjust rows to make it fit maximized
config.initial_cols = 120

return config
