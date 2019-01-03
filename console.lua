local api = require "api"
local pretty = require "pretty"

local function ssplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end


local console = {
    workdir = '/',
    path = {},
    root = root
}


function console.cd(_, dir)
    local path
    if starts_with(dir, '/') then
        path = ssplit(dir, "/")
    else
        path = console.path
        local pe = ssplit(dir, "/")
        for _, f in ipairs(pe) do
            path[#path + 1] = f
        end
    end
    local realPath = {}
    for _, f in ipairs(path) do
        if f == "." then
        elseif f == ".." then
            table.remove(realPath, #realPath)
        else
            realPath[#realPath + 1] = f
        end
    end
    console.path = realPath
    console.workdir = table.concat(console.path, "/")
end

function console.pwd() 
    print(console.workdir)
end


function console.setkey(_, key)
    api.setApiKey(key)
end

--TODO
function console.refresh()
    api.RefreshAll()
end

function console.ls(_, path)
end

while true do
    io.write(console.workdir .. " -> ")
    local cmds = io.read("*l")
    if cmds == "exit" then
        break
    end
    cmds = ssplit(cmds, " ")
    if #cmds > 0 then
        local func = console[cmds[1]]
        if func and type(func) == "function" then
            func(unpack(cmds))
        end
    end
end
