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

local function get_icon(title)
	-- List of prefixes to try
	local prefixes = { "md", "md_language", "md_code", "dev", "fa" } -- Add more prefixes as needed
	-- Treat these titles as equivalent to "node"
	local node_specific_titles = { "node", "nodejs", "bun", "npm", "yarn", "pnpm" }

	if title == "dockerfile" then
		title = "docker"
	end
	if title == "neo-tree" then
		title = "file_tree"
	end
	if title == "toggleterm" then
		title = "terminal"
	end
	if title == "snacks_terminal" then
		title = "git"
	end
	if title == "TelescopeResults" then
		title = "search"
	end
	-- Normalize titles to "node" for node-specific terms
	for _, node_title in ipairs(node_specific_titles) do
		if title == node_title then
			title = "nodejs_small"
			break
		end
	end

	-- Try to find an icon with the normalized title or title+js
	for _, prefix in ipairs(prefixes) do
		-- Try original title
		local key = prefix .. "_" .. title
		local icon = wezterm.nerdfonts[key]
		if icon then
			return icon
		end

		-- Try with 'js' suffix
		key = prefix .. "_" .. title .. "js"
		icon = wezterm.nerdfonts[key]
		if icon then
			return icon
		end
	end

	return wezterm.nerdfonts.cod_terminal_ubuntu
end

wezterm.on("format-tab-title", function(tab, tabs, _, _, _, max_width)
	local active = tab.is_active
	local background = "#1b1b1b"
	local div = dividers[config.dividers] or dividers.slant_right
	local pane = tab.active_pane
	local cwd = pane.current_working_dir and wezterm.to_string(pane.current_working_dir) or nil
	local url = nil

	-- Parse the working directory URL if valid
	if cwd and cwd:match("^file://") then
		url = wezterm.url.parse(cwd)
	else
		wezterm.log_info("Invalid or missing working directory: ", cwd)
	end

	-- Determine the colors
	local color_index = (tab.tab_index % #rainbow_colors) + 1
	local bg_color = active and rainbow_colors[color_index] or "#313244"
	-- local fg_color = active and "#313444" or "#666666"
	local fg_color = active and "#ECEFF4" or "#666666"

	-- Get the icon or title
	local title = get_icon(pane.title)
	-- wezterm.log_info("pane => ", pane.title)
	-- Simplify path and build the title
	-- local simplified_path = url and simplify_path(url.path or "") or ""
	-- local title = string.format("%s  %s", display_title, simplified_path)
	-- local title = string.format("%s", display_title)

	-- Check if the title overlaps with the path
	-- if string.find(cwd or "", pane.title:gsub("%.%.+", ""), 1, true) or simplified_path == pane.title then
	-- 	title = pane.title -- Show only the pane title
	-- end

	-- Truncate the title if it exceeds max width
	-- if #title > max_width then
	-- 	title = wezterm.truncate_right(title, max_width - 5) .. "…"
	-- end

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

wezterm.on("update-right-status", function(window, pane)
	local cells = {}
	local div = dividers[config.dividers] or dividers.slant_right

	-- Add initial slant cell
	table.insert(cells, wezterm.nerdfonts.cod_folder_opened)

	-- Handle CWD and hostname
	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri then
		local cwd = ""
		local hostname = ""
		if type(cwd_uri) == "userdata" then
			cwd = cwd_uri.file_path
			hostname = cwd_uri.host or wezterm.hostname()
		else
			cwd_uri = cwd_uri:sub(8)
			local slash = cwd_uri:find("/")
			if slash then
				hostname = cwd_uri:sub(1, slash - 1)
				cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
					return string.char(tonumber(hex, 16))
				end)
			end
		end
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		if hostname == "" then
			hostname = wezterm.hostname()
		end

		table.insert(cells, wezterm.nerdfonts.custom_folder_open .. " " .. simplify_path(cwd))
	end

	local date = wezterm.strftime("%a %b %-d, %H:%M")
	table.insert(cells, date)

	for _, b in ipairs(wezterm.battery_info()) do
		local charge = math.floor(b.state_of_charge * 100)
		local battery_icon

		if charge == 100 then
			-- battery_icon = wezterm.nerdfonts.md_battery
			battery_icon =
				wezterm.nerdfonts[(b.state == "Unknown" or b.state == "Full") and "md_battery_charging_100" or "md_battery"]
		else
			local icon_level = math.floor(charge / 10) * 10
			icon_level = math.max(10, math.min(100, icon_level))
			local icon_name = b.state == "Charging" and "md_battery_charging_" or "md_battery_"
			battery_icon = wezterm.nerdfonts[icon_name .. icon_level]
		end
		table.insert(cells, battery_icon .. " " .. string.format("%.0f%%", charge))
	end

	local colors = {
		"#282C34", -- Background color for initial slant
		"#61AFEF", -- Blue
		"#E5C07B", -- Yellow
		"#98C379", -- Green
	}

	local text_fg = "#333333"
	local elements = {}
	local num_cells = 0

	local function push(text, is_last)
		local cell_no = num_cells + 1
		if cell_no == 1 then
			-- First cell (empty) just needs the slant
			table.insert(elements, { Foreground = { Color = "#1b1b1b" } })
			table.insert(elements, { Background = { Color = colors[2] } })
			table.insert(elements, { Text = div.right })
		else
			-- For all other cells
			local current_fg = (cell_no == 2) and "#ECEFF4" or text_fg
			table.insert(elements, { Foreground = { Color = current_fg } })
			table.insert(elements, { Background = { Color = colors[cell_no] } })
			table.insert(elements, { Text = " " .. text .. " " })
			if not is_last then
				table.insert(elements, { Foreground = { Color = colors[cell_no] } })
				table.insert(elements, { Background = { Color = colors[cell_no + 1] } })
				table.insert(elements, { Text = div.right })
			end
		end
		num_cells = num_cells + 1
	end

	while #cells > 0 do
		local cell = table.remove(cells, 1)
		push(cell, #cells == 0)
	end

	window:set_right_status(wezterm.format(elements))
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
