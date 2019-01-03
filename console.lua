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

local function equal_with(str, equal)
    return str == equal
end



local console = {
    workdir = '/',
    path = {},
    root = root
}


function console.calcPath(dir)
    dir = dir or '.'
    local path
    if starts_with(dir, '/') then
        path = ssplit(dir, "/")
    else
        path = {}
        for _, p in ipairs(console.path) do
            path[#path + 1] = p
        end
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
    return realPath
end

function console.cd(_, dir)
    console.path = console.calcPath(dir)
    console.workdir = table.concat(console.path, "/")
end

function console.pwd() 
    print(console.workdir)
end


function console.setkey(_, key)
    api.setApiKey(key)
    api.RefreshAll()
end

--TODO
function console.refresh()
    api.RefreshAll()
end

function console.getFolderId(path)
    local realPath = console.calcPath(path)
    local root = api.root
    for _, folder in ipairs(realPath) do
        for _, fr in ipairs(root.folders) do
            if fr.name == folder then
                root = fr
                break
            end
        end
    end
    return root.id
end

function console.getFileInfo(path)
    local realPath = console.calcPath(path)
    local root = api.root
    local filename = realPath[#realPath]
    table.remove(realPath, #realPath)
    for _, folder in ipairs(realPath) do
        for _, fr in ipairs(root.folders) do
            if fr.name == folder then
                root = fr
                break
            end
        end
    end

    local cfunc
    local cstr
    if starts_with(filename, "*") then
        cfunc = ends_with
        cstr = filename:sub(2)
    elseif ends_with(filename, "*") then
        cfunc = starts_with
        cstr = filename:sub(1, #filename - 1)
    else
        cfunc = equal_with
        cstr = filename
    end

    local fis = {}
    for _, file in ipairs(root.files) do
        if cfunc(file.filename, cstr) then
            fis[#fis + 1] = file
        end
    end
    return fis
end


function console.ls(_, path)
    local realPath = console.calcPath(path)
    local root = api.root
    for _, folder in ipairs(realPath) do
        for _, fr in ipairs(root.folders) do
            if fr.name == folder then
                root = fr
                break
            end
        end
    end

    for _, file in ipairs(root.files or {}) do
        print(file.filename)
    end
    for _, folder in ipairs(root.folders or {}) do
        print(folder.name)
    end
end

function console.rmdir(_, path)
    local folderId = console.getFolderId(path)
    api.removeFolder(folderId)
end

function console.mkdir(_, name)
    local folderId = console.getFolderId(console.workdir)
    api.makeFolder(name, folderId)
end

function console.rm(_, path)
    local fileInfos = console.getFileInfo(path)
    local urls = {}
    for _, fi in ipairs(fileInfos) do
        urls[#urls + 1] = fi.url
    end
    api.removeFiles(urls)
end

function console.mv(_, path, dst)
    local fileInfos = console.getFileInfo(path)
    local urls = {}
    for _, fi in ipairs(fileInfos) do
        urls[#urls + 1] = fi.url
    end
    local folderId = console.getFolderId(dst)
    api.moveFiles(urls, folderId)
end

function console.cp(_, path, dst)
    local fileInfos = console.getFileInfo(path)
    local urls = {}
    for _, fi in ipairs(fileInfos) do
        urls[#urls + 1] = fi.url
    end
    local folderId = console.getFolderId(dst)
    api.copyFiles(urls, folderId)
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
