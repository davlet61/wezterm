local wezterm = require("wezterm")
local tab_bar = {}

-- Unicode characters for different divider styles
local dividers = {
	slant_right = { left = "\u{e0be}", right = "\u{e0bc}" },
	slant_left = { left = "\u{e0ba}", right = "\u{e0b8}" },
	arrows = { left = "\u{e0b2}", right = "\u{e0b0}" },
	rounded = { left = "\u{e0b6}", right = "\u{e0b4}" },
}

-- Rainbow colors for tabs
local rainbow_colors = {
	"#E06C75", -- Red
	"#E5C07B", -- Yellow
	"#98C379", -- Green
	"#56B6C2", -- Cyan
	"#61AFEF", -- Blue
	"#C678DD", -- Purple
}

-- Default settings
local config = {
	position = "bottom",
	max_width = 32,
	dividers = "slant_right",
	clock = { enabled = true, format = "%H:%M:%S" },
}

-- Function to merge configurations
local function tableMerge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				tableMerge(t1[k], t2[k])
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

-- Format the tab titles with rainbow colors
wezterm.on("format-tab-title", function(tab, tabs, _, conf, _, max_width)
	local active = tab.is_active

	-- Get the current color based on tab index
	local color_index = (tab.tab_index % #rainbow_colors) + 1
	local bg_color = active and rainbow_colors[color_index] or "#313244"
	local fg_color = active and "#ECEFF4" or "#666666"

	-- Get the divider style
	local div = dividers[config.dividers] or dividers.slant_right

	-- Get the tab title
	local index = (tab.tab_index + 1)
	local title = string.format("%d:%s", index, tab.active_pane.title)
	if #title > max_width then
		title = wezterm.truncate_right(title, max_width - 2) .. "…"
	end

	return {
		{ Background = { Color = bg_color } },
		{ Foreground = { Color = fg_color } },
		{ Text = " " .. title .. " " .. div.right },
	}
end)

-- Update the status bar with a clock
wezterm.on("update-status", function(window, _)
	if config.clock and config.clock.enabled then
		local time = wezterm.time.now():format(config.clock.format)
		window:set_right_status(wezterm.format({
			{ Foreground = { Color = "#88C0D0" } },
			{ Background = { Color = "#2E3440" } },
			{ Text = " " .. time .. " " },
		}))
	end
end)

-- Apply tab bar configuration
function tab_bar.apply_to_config(c, opts)
	if opts then
		config = tableMerge(config, opts)
	end

	-- Apply the configuration
	c.use_fancy_tab_bar = false
	c.tab_bar_at_bottom = config.position == "bottom"
	c.tab_max_width = config.max_width
	c.enable_tab_bar = true
	c.hide_tab_bar_if_only_one_tab = true

	-- Ensure proper colors
	c.colors = c.colors or {}
	c.colors.tab_bar = {
		background = "#1b1b1b",
	}
end

return tab_bar
