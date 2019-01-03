local requests = require('requests')
local cjson = require('cjson')

local api = {
    root = {},
    fmaps = {}
}

function api.setApiKey(key)
    api.key = key
end

function api.oneFichierPost(url, data)
    local headers = {Authorization = "Bearer " .. api.key, ['Content-Type'] = 'application/json'}
    local response = requests.post{ url, headers = headers, data=data }
    --TODO: error check
    return cjson.decode(response.text)
end

function api.folderList(folderId)
    local data = {folder_id=folderId}
    api.oneFichierPost('https://api.1fichier.com/v1/folder/ls.cgi', data)
end

function api.fileList(folderId)
    local data = {folder_id=folderId}
    api.oneFichierPost('https://api.1fichier.com/v1/file/ls.cgi', data)
end

function api.moveFiles(urls, folderId)
    local data = {urls = urls, destination_folder_id = folderId}
    api.oneFichierPost('https://api.1fichier.com/v1/file/mv.cgi', data)
end

function api.copyFiles(urls, folderId)
    local data = {urls = urls, destination_folder_id = folderId}
    api.oneFichierPost('https://api.1fichier.com/v1/file/cp.cgi', data)
end

function api.removeFiles(urls)
    local files = { }
    for _, url in ipairs(urls) do
        files[#files + 1] =  {url = url}
    end
    local data = { files = files }
    api.oneFichierPost('https://api.1fichier.com/v1/file/rm.cgi', data)
end

function api.getFileLink(url)
    local data = { url = url }
    api.oneFichierPost('https://api.1fichier.com/v1/download/get_token.cgi', data)
end

function api.makeFolder(foldname, foldId)
    local data = { name = foldname, folder_id = foldId }
    api.oneFichierPost('https://api.1fichier.com/v1/folder/mkdir.cgi', data)
end

function api.moveFolder(folderId, dstId)
    local data = { folder_id = folderId, destination_folder_id = dstId }
    api.oneFichierPost('https://api.1fichier.com/v1/folder/mv.cgi', data)
end

function api.removeFolder(folderId)
    local data = { folder_id = folderId }
    api.oneFichierPost('https://api.1fichier.com/v1/folder/rm.cgi', data)
end

function api.listAll(root, folderId)
    root.files = api.fileList(folderId).items
    root.folders = api.folderList(folderId).sub_folders or {}
    api.fmaps[folderId] = root
    for _, file in pairs(root.files) do
        file.fatherId = folderId
    end
    for _, folder in pairs(root.folders) do
        folder.fatherId = folderId
        api.listAll(folder, folder.id)
    end
end

function api.RefreshAll()
    api.root = {}
    api.listAll(api.root, 0)
end

return api
