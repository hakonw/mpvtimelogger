-- This script logs total time used in mpv
-- The default key to display total watch time is "k"
--
-- This can be overwritten by editing the last line in this script
-- Or add the following to your input.conf to change the default keybinding:
-- KEY script-binding display_total_watch_time

-- To set another path for the logfile, please uncomment one of the linues below
-- local logpath = "C:\Users\user\AppData\Roaming\mpv\time.log"
-- local logpath = "/home/user/.config/mpv/time.log"

-- Set to true to disply the time in days, hours, min and sec (instead of hours, min, sec)
local timeformatindays = false

-- Set to true to disable looging of the filename
local incognito = false


-- automaticly sets the logpath
function detect_logpath()
    if (logpath ~= nil) or (logpath == "") then return end
    if os.getenv("APPDATA") ~= nil then
        logpath = os.getenv("APPDATA") .. "\\mpv\\time.log" -- for windows
    else
        logpath = os.getenv("HOME") .. "/.config/mpv/time.log" -- for unix based
    end
end

-- gets file name and resets values
function on_file_load(event)
    totaltime = 0
    lasttime = os.clock()
    timeloaded = os.date("%c")
    paused = mp.get_property_bool("pause")
    filename = "null"
    if not incognito then filename = mp.get_property("path") end
    file_exists(logpath)
end

-- adds time to totaltime on pause
function on_pause_change(name, pausing)
    if pausing == true then
        totaltime = totaltime + os.clock() - lasttime
    else
        lasttime = os.clock()
    end
    paused = pausing
end

-- checks if there are file problems
function file_exists(path)
    local f, err = io.open(path, "a")
    if f == nil then
        mp.osd_message("timelogger - Error opening file, error: " .. err)
        mp.msg.error("Error opening file, error: " .. err)
        return false
    end
    f:close()
    return true
end

-- write to file when exiting the player or switching file
function on_file_end(event)
    if not paused then totaltime = totaltime + os.clock() - lasttime end
    if file_exists(logpath) then
        file = io.open(logpath, "a")
        file:write(totaltime .. "s, " .. timeloaded .. ", " .. filename, "\n")
        file:close()
    end
end

-- helper for time_format returns reduced time, string
function time_format_helper(time, divider, suffix)
    if time >= divider then
        return math.mod(time, divider), (math.floor(time / divider) .. suffix .. " ")
    end
    return time, ""
end

-- transforms the time from s to (days), hours, min, sec
function time_format(time)
    local s = ""
    local start = 1
    local times = {86400, 3600, 60, 1}
    local suffixes = {"d", "h", "m", "s"}
    if not timeformatindays then start = 2 end
    for i = start, 4, 1 do
        time, string = time_format_helper(time, times[i], suffixes[i])
        s = s .. string
    end
    return s
end

-- displays total time
function total_time()
    if not file_exists then return nil end
    local total = 0
    for line in io.lines(logpath) do
        local s1, s2 = string.match(line, "(.-)s,(.*)") -- non-greedy matching in lua is "-"
        total = total + tonumber(s1)
    end
    total = total + totaltime
    if not paused then total = total + os.clock() - lasttime end
    mp.osd_message("Total logged time: " .. time_format(total))
end

detect_logpath()
mp.register_event("file-loaded", on_file_load)
mp.register_event("end-file", on_file_end)
mp.observe_property("pause", "bool", on_pause_change)
mp.add_key_binding("k", "display_total_watch_time", total_time)
