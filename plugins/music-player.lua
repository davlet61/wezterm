local wez = require("wezterm")
local utilities = require("plugins.utilities")

local M = {}
local last_update = 0
local stored_playback = ""
local stored_status = ""

-- Icons for music controls (using Nerd Fonts)
M.icons = {
	play = wez.nerdfonts.md_play,
	pause = wez.nerdfonts.md_pause,
	next = wez.nerdfonts.md_skip_next,
	prev = wez.nerdfonts.md_skip_previous,
	music = wez.nerdfonts.md_music_note,
}

-- Control functions
function M.play_pause()
	wez.run_child_process({ "playerctl", "--player=chromium", "play-pause" })
end

function M.next_track()
	wez.run_child_process({ "playerctl", "--player=chromium", "next" })
end

function M.prev_track()
	wez.run_child_process({ "playerctl", "--player=chromium", "previous" })
end

function M.get_play_status()
	local success, status = wez.run_child_process({
		"playerctl",
		"--player=chromium",
		"status",
	})
	if success then
		stored_status = utilities._trim(status)
		return stored_status
	end
	return stored_status
end

local format_playback = function(pb, max_width)
	if not pb or pb == "" then
		return ""
	end

	if #pb <= max_width then
		return pb
	end

	local artist, track = pb:match("^(.-) %- (.+)$")
	if artist and track then
		local pb_main_artist = artist:match("([^,]+)") .. " - " .. track
		if #pb_main_artist <= max_width then
			return pb_main_artist
		end
		return track:sub(1, max_width)
	end

	return pb:sub(1, max_width)
end

M.get_currently_playing = function(max_width, throttle)
	if utilities._wait(throttle, last_update) then
		return stored_playback
	end

	local success, title = wez.run_child_process({
		"playerctl",
		"--player=chromium",
		"metadata",
		"title",
	})

	local artist_success, artist = wez.run_child_process({
		"playerctl",
		"--player=chromium",
		"metadata",
		"artist",
	})

	if not success then
		return ""
	end

	title = utilities._trim(title or "")
	artist = utilities._trim(artist or "")

	local playback = artist ~= "" and artist .. " - " .. title or title
	local res = format_playback(playback, max_width)
	stored_playback = res
	last_update = os.time()
	return res
end

return M
