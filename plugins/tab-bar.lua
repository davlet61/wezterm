local wezterm = require("wezterm")
local tab_bar = {}

local dividers = {
	slant_right = {
		left = wezterm.nerdfonts.ple_lower_right_triangle,
		right = wezterm.nerdfonts.ple_upper_left_triangle,
	},
	slant_left = {
		left = wezterm.nerdfonts.ple_upper_right_triangle,
		right = wezterm.nerdfonts.ple_lower_left_triangle,
	},
	arrows = {
		left = wezterm.nerdfonts.pl_right_hard_divider,
		right = wezterm.nerdfonts.pl_left_hard_divider,
	},
	rounded = {
		left = wezterm.nerdfonts.ple_left_half_circle_thick,
		right = wezterm.nerdfonts.ple_right_half_circle_thick,
	},
}

local rainbow_colors = {
	"#E06C75", -- Red
	"#E5C07B", -- Yellow
	"#98C379", -- Green
	"#56B6C2", -- Cyan
	"#61AFEF", -- Blue
	"#C678DD", -- Purple
}

local config = {
	position = "bottom",
	max_width = 32,
	dividers = "slant_right",
	clock = { enabled = true, format = "%H:%M:%S" },
}

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

local function simplify_path(path)
	return path:gsub("^" .. wezterm.home_dir, "~")
end

local function get_icon_or_title(title)
	-- List of prefixes to try
	local prefixes = { "dev", "md", "fa" } -- Add more prefixes as needed

	-- Iterate through prefixes and attempt to find a matching icon
	for _, prefix in ipairs(prefixes) do
		local key = prefix .. "_" .. title
		local icon = wezterm.nerdfonts[key]
		if icon then
			return icon -- Return the icon if found
		end
	end

	-- If no icon is found, return the original title
	return title
end

wezterm.on("format-tab-title", function(tab, tabs, _, _, _, max_width)
	local active = tab.is_active
	local background = "#1b1b1b"
	local div = dividers[config.dividers] or dividers.slant_right
	local pane = tab.active_pane
	local cwd = wezterm.to_string(pane.current_working_dir)
	local url = wezterm.url.parse(cwd)

	-- wezterm.log_info("Includes => ", string.find(cwd, pane.title:gsub("%.%.+", ""), 1, true), pane.title)

	-- Get the current color based on tab index
	local color_index = (tab.tab_index % #rainbow_colors) + 1
	local bg_color = active and rainbow_colors[color_index] or "#313244"
	local fg_color = active and "#ECEFF4" or "#666666"
	-- Get the tab title
	-- local index = (tab.tab_index + 1)
	-- local title = string.format("%d:%s", index, tab.active_pane.title)

	local display_title = get_icon_or_title(pane.title)
	local title = string.format("%s:%s", display_title, simplify_path(url.path))
	if string.find(cwd, pane.title:gsub("%.%.+", ""), 1, true) then
		title = string.format("%s", pane.title)
	end

	if #title > max_width then
		title = wezterm.truncate_right(title, max_width - 2) .. "…"
	end

	local elements = {}

	-- Tab content
	table.insert(elements, { Background = { Color = bg_color } })
	table.insert(elements, { Foreground = { Color = fg_color } })
	table.insert(elements, { Text = " " .. title .. " " })

	-- Right divider
	local next_tab = tabs[tab.tab_index + 2]
	if next_tab then
		local next_color_index = ((tab.tab_index + 1) % #rainbow_colors) + 1
		local next_bg_color = next_tab.is_active and rainbow_colors[next_color_index] or "#313244"
		table.insert(elements, { Background = { Color = next_bg_color } })
		table.insert(elements, { Foreground = { Color = bg_color } })
	else
		-- Last tab: Ensure proper right alignment
		table.insert(elements, { Background = { Color = background } })
		table.insert(elements, { Foreground = { Color = bg_color } })
	end
	table.insert(elements, { Text = div.right })

	return elements
end)

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

function tab_bar.apply_to_config(c, opts)
	if opts then
		config = tableMerge(config, opts)
	end

	c.use_fancy_tab_bar = false
	c.tab_bar_at_bottom = config.position == "bottom"
	c.tab_max_width = config.max_width
	c.enable_tab_bar = true
	c.hide_tab_bar_if_only_one_tab = true

	c.colors = c.colors or {}
	c.colors.tab_bar = {
		background = "#1b1b1b",
		new_tab = { bg_color = "#313244", fg_color = "#ECEFF4" },
		inactive_tab = { bg_color = "#313244", fg_color = "#666666" },
		active_tab = { bg_color = "#313244", fg_color = "#ECEFF4" },
	}
end

return tab_bar
