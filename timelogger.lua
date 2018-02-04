local totaltime = 0
local lasttime = os.clock()
local filename = ""
-- savepath to logfile
local savepath = os.getenv("APPDATA") .. "\\mpv\\time.txt"
-- local savepath = "C:\Users\user\AppData\Roaming\mpv\time.txt"


-- adds time to totaltime
function pause_manager(name, value)
    if value == true then
        totaltime = totaltime + os.clock() - lastttime
    else
        lastttime = os.clock()
    end
end

-- get file name
function startup(event)
    filename = mp.get_property("path")
end

-- check if file problems
function file_exists(file)
    local f, err = io.open(file, "rb")
    if f == nil then
      msg.error("Error opening file, error:" .. err)
      print(err)
      return false
    end
    f:close()
    return true
end

-- write to file
function shutdown(event)
    if file_exists(savepath) then
        file = io.open(savepath, "a")
        file:write(totaltime .. "s, " .. os.date("%c") .. ", " .. filename, "\n")
        file:close()
    end
end

-- gets total time
function total_time()
    if not file_exists then return nil end
    
    local total = 0
    for line in io.lines(savepath)
        local s1, s2 = string:match(line, "(.?)s,(.*)")
        total = total + s1
    end
    -- TODO: Transform time in s to days, hours, min, sec
    mp.osd_message("Total time used: " .. total)
end

mp.observe_property("pause", "bool", pause_manager)
mp.register_event("file-loaded", startup)
mp.register_event("shutdown", shutdown)
mp.add_key_binding("k","total_watch_time", total_time)
