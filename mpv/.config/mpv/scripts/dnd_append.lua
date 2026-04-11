local mp = require("mp")

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function uri_decode(s)
	return s:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

local function normalize_item(line)
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

local function split_lines(text)
	local items = {}

	for line in text:gmatch("[^\r\n]+") do
		line = normalize_item(line)
		if line and line ~= "" then
			table.insert(items, line)
		end
	end

	return items
end

local function append_items(items)
	local count = 0

	for _, item in ipairs(items) do
		mp.commandv("loadfile", item, "append-play")
		count = count + 1
	end

	if count > 0 then
		mp.osd_message("Appended " .. count .. " dropped file(s)")
	end
end

local function on_drop(arg)
	if not arg or arg == "" then
		return
	end

	local items = split_lines(arg)
	if #items == 0 then
		return
	end

	append_items(items)
end

mp.register_event("drag-and-drop", function(event)
	if type(event) == "table" and event.arg then
		on_drop(event.arg)
	elseif type(event) == "string" then
		on_drop(event)
	end
end)
