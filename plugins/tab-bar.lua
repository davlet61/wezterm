local wezterm = require("wezterm")
local tab_bar = {}

local dividers = {
	slant_right = { left = "\u{e0be}", right = "\u{e0bc}" },
	slant_left = { left = "\u{e0ba}", right = "\u{e0b8}" },
	arrows = { left = "\u{e0b2}", right = "\u{e0b0}" },
	rounded = { left = "\u{e0b6}", right = "\u{e0b4}" },
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

wezterm.on("format-tab-title", function(tab, tabs, _, conf, _, max_width)
	local active = tab.is_active
	local background = "#1b1b1b"
	local div = dividers[config.dividers] or dividers.slant_right

	-- Get the current color based on tab index
	local color_index = (tab.tab_index % #rainbow_colors) + 1
	local bg_color = active and rainbow_colors[color_index] or "#313244"
	local fg_color = active and "#ECEFF4" or "#666666"

	-- Get the tab title
	local index = (tab.tab_index + 1)
	local title = string.format("%d:%s", index, tab.active_pane.title)
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
