local totaltime = 0
local lasttime = 0
local timeloaded = ""
local filename = ""
local paused = false
-- set to true to disply in days, hours, min and sec (instead of hours, min, sec)
local timeformatindays = false
-- path to logfile
local logpath = os.getenv("APPDATA") .. "\\mpv\\time.txt"
-- local logpath = "C:\Users\user\AppData\Roaming\mpv\time.txt"
-- local logpath = "~/.config/mpv/time.txt"

-- gets file name and resets values
function on_file_load(event)
    totaltime = 0
    lasttime = os.clock()
    timeloaded = os.date("%c")
    filename = mp.get_property("path")
    paused = mp.get_property_bool("pause")
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
    local f, err = io.open(path, "rb")
    if f == nil then
        msg.error("Error opening file, error:" .. err)
        print(err)
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
        return math.mod(time,divider), (math.floor(time/divider) .. suffix .. " ")
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
    for i=start,4,1 do
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
        local s1, s2 = string.match(line, "(.*)s,(.*)")
        total = total + tonumber(s1)
    end
    total = total + totaltime
    if not paused then total = total + os.clock() - lasttime end
    mp.osd_message("Total logged time: " .. time_format(total))
end

mp.register_event("file-loaded", on_file_load)
mp.register_event("end-file", on_file_end)
mp.observe_property("pause", "bool", on_pause_change)
mp.add_key_binding("k","display_total_watch_time", total_time)
