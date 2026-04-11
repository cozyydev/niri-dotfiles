local mp = require("mp")

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function uri_decode(s)
	return s:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

local function normalize_path(line)
	line = trim(line)
	if line == "" then
		return nil
	end

	if line:match("^file://") then
		line = line:gsub("^file://", "")
		line = uri_decode(line)
	end

	return line
end

local function get_clipboard()
	local res = mp.command_native({
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		capture_stderr = true,
		args = { "wl-paste", "--no-newline" },
	})

	if not res or res.status ~= 0 or not res.stdout then
		return nil
	end

	return res.stdout
end

local function paste_append()
	local text = get_clipboard()
	if not text or text == "" then
		mp.osd_message("Clipboard empty")
		return
	end

	local added = 0

	for line in text:gmatch("[^\r\n]+") do
		local path = normalize_path(line)
		if path and path ~= "" then
			mp.commandv("loadfile", path, "append-play")
			added = added + 1
		end
	end

	if added > 0 then
		mp.osd_message("Appended " .. added .. " file(s)")
	else
		mp.osd_message("No valid files in clipboard")
	end
end

mp.add_key_binding("Ctrl+v", "paste-append", paste_append)
