SmartFilterSettings = {}
SmartFilterSettings.cachedFilters = nil

local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth * 4)
    if name then
        if type(name) == "number" then
            tmp = tmp .. "[" .. name .. "] = "
        else
            tmp = tmp .. "[\"" .. tostring(name) .. "\"] = "
        end
    end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
        local first = true
        for k, v in pairs(val) do
            if not first then
                tmp = tmp .. "," .. (not skipnewlines and "\n" or "")
            end
            tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1)
            first = false
        end
        tmp = tmp .. (not skipnewlines and "\n" or "") .. string.rep(" ", depth * 4) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[unsupported type]\""
    end
    return tmp
end

function SmartFilterSettings.getFileName()
    local saveName = "UnknownSave"
    if getWorld() and getWorld():getWorld() then
        saveName = getWorld():getWorld()
    end
    return "SmartFilter_" .. saveName .. ".lua"
end

function SmartFilterSettings.loadFilters()
    local fileName = SmartFilterSettings.getFileName()
    local reader = getFileReader(fileName, true)
    if not reader then
        SmartFilterSettings.cachedFilters = {}
        return SmartFilterSettings.cachedFilters
    end
    
    local content = ""
    while true do
        local line = reader:readLine()
        if not line then break end
        content = content .. line .. "\n"
    end
    reader:close()
    
    if content == "" then
        SmartFilterSettings.cachedFilters = {}
    else
        -- Safely load the lua table
        local func = loadstring(content)
        if func then
            local success, result = pcall(func)
            if success and type(result) == "table" then
                SmartFilterSettings.cachedFilters = result
            else
                SmartFilterSettings.cachedFilters = {}
            end
        else
            SmartFilterSettings.cachedFilters = {}
        end
    end
    
    return SmartFilterSettings.cachedFilters
end

function SmartFilterSettings.saveFilters()
    local fileName = SmartFilterSettings.getFileName()
    local writer = getFileWriter(fileName, true, false)
    if not writer then return end
    
    local filters = SmartFilterSettings.cachedFilters or {}
    local serialized = "return " .. serializeTable(filters, nil, false, 0)
    
    for line in string.gmatch(serialized, "([^\n]+)") do
        writer:writeln(line)
    end
    
    writer:close()
end

function SmartFilterSettings.getFilters()
    if SmartFilterSettings.cachedFilters then
        return SmartFilterSettings.cachedFilters
    end
    return SmartFilterSettings.loadFilters()
end
