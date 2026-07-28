local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	local cached = isfile(path) and pcall(readfile, path) or false
	if not cached or cached == '' then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/jackwallhack8/Autumn/'..'refs/heads/main'..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local function downloadPremadeProfiles(commit)
    local httpService = game:GetService('HttpService')
    
    if isfolder('newvape/profiles/premade') then
        for _, file in listfiles('newvape/profiles/premade') do
            pcall(function()
                if isfile(file) then
                    delfile(file)
                end
            end)
        end
    else
        makefolder('newvape/profiles/premade')
    end

    local success, response = pcall(function()
        return game:HttpGet('https://api.github.com/repos/jackwallhack8/Autumn/contents/profiles/premade?ref=' .. commit)
    end)

    if success and response then
        local ok, files = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if ok and type(files) == 'table' then
            for _, file in pairs(files) do
                if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
					local baseName = (file.name:match('^(.-)%.txt$') or file.name):gsub('%d+$', '')
					local fileId = (game.GameId == 2619619496) and game.GameId or game.PlaceId
					local filePath = 'newvape/profiles/premade/' .. baseName .. tostring(fileId) .. '.txt'
					local ds, dc = pcall(function()
						return game:HttpGet(file.download_url, true)
					end)
					if ds and dc and dc ~= '404: Not Found' then
						writefile(filePath, dc)
					end
                end
            end
        end
    end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/jackwallhack8/Autumn')
	end)

	local commit = 'main'
	local ok, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/jackwallhack8/Autumn/refs/heads/main/commit.txt', true)
	end)

	if ok and res then
		local h = res:match('^%s*([a-f0-9]+)')
		if h and #h == 40 then
			commit = h
		end
	end

	local cachedCommit = isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or ''
	if (commit ~= 'main' and cachedCommit ~= commit) or (commit == 'main' and cachedCommit ~= '' and cachedCommit ~= 'main') then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
		if isfolder('newvape/profiles/premade') then
			for _, file in listfiles('newvape/profiles/premade') do
				pcall(function()
					if isfile(file) then
						delfile(file)
					end
				end)
			end
		end
		for _, p in ipairs({'newvape/main.lua', 'newvape/games/universal.lua', 'newvape/guis/new.lua'}) do
			if isfile(p) then pcall(delfile, p) end
		end
	end

	writefile('newvape/profiles/commit.txt', commit)
	pcall(downloadPremadeProfiles, commit)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
