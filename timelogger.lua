local totaltime = 0
local filename = ""
-- how often to add seconds
local updatetime = 1
-- savepath to logfile
local savepath = os.getenv("APPDATA") .. "\\mpv\\time.txt"
-- local savepath = "C:\Users\user\AppData\Roaming\mpv\time.txt"


-- pauses and starts timer
function pause_manager(name, value)
    if value == true then
        timer:stop()
    else
        timer:resume()
    end
end

-- update total second variable
function update()
    totaltime = totaltime + updatetime
end

-- get file name
function startup(event)
    filename = mp.get_property("path")
end

-- write to file
function shutdown(event)
    file, err = io.open(savepath, "a")
    if file == nil then
        --msg.error("Error opening file")
        print(err)
    else
        file:write(totaltime .. "s, " .. os.date("%c") .. ", " .. filename, "\n")
        file:close()
    end
end

timer = mp.add_periodic_timer(updatetime, update);
mp.observe_property("pause", "bool", pause_manager)
mp.register_event("file-loaded", startup)
mp.register_event("shutdown", shutdown)
