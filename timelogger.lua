local totaltime = 0
local lasttime = 0
local timeloaded = ""
local filename = ""
local paused = false
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
    -- TODO: Transform time from s to days, hours, min, sec
    mp.osd_message("Total time used: " .. total)
end

mp.register_event("file-loaded", on_file_load)
mp.register_event("end-file", on_file_end)
mp.observe_property("pause", "bool", on_pause_change)
mp.add_key_binding("k","display_total_watch_time", total_time)
