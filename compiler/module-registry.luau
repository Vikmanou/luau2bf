--!nocheck

local fs = (require :: any)('@lute/fs')

local ModuleRegistry = {}

local SKIP_DIRS = {
	optimization = true,
}

local function mergeExports(registry: { [string]: any }, modulePath: string, exports: { [string]: any })
	for key, value in exports do
		if registry[key] ~= nil then
			error(`Duplicate registry key '{key}' from '{modulePath}'`)
		end
		registry[key] = value
	end
end

local function loadDirectory(registry: { [string]: any }, dirPath: string, requirePath: string)
	local entries = fs.listdir(dirPath)
	table.sort(entries, function(left, right)
		return left.name < right.name
	end)

	for _, entry in entries do
		local nextDirPath = `{dirPath}/{entry.name}`
		if entry.type == 'file' and entry.name:find('%.luau$') and entry.name ~= 'init.luau' then
			local moduleName = entry.name:gsub('%.luau$', '')
			local modulePath = `{requirePath}/{moduleName}`
			local exports = (require)(modulePath)
			mergeExports(registry, modulePath, exports)
		elseif entry.type ~= 'file' and not SKIP_DIRS[entry.name] then
			loadDirectory(registry, nextDirPath, `{requirePath}/{entry.name}`)
		end
	end
end

function ModuleRegistry.load(dirPath: string, requirePath: string): { [string]: any }
	local registry = {}
	loadDirectory(registry, dirPath, requirePath)
	return registry
end

return ModuleRegistry