AutoUpdater = require("auto_updater")
config = require("config")
data = require("state")
packLua = require("pack_lua")
BoosterUrls = require("booster_urls")
PackBuilder = require("pack_builder")
setDefinitions = require("set_definitions")

-----------------------------------------------------------------------
-- Main script
-----------------------------------------------------------------------

function onLoad(savedData)
    PackBuilder.bindSharedQueryCaches()
    updateObject(false)
    data.lastDescription = self.getDescription()
    if data.setCode == config.defaultSetCode then
        self.addContextMenuItem("Spawn Boxes", spawnSupportedPacks)
    end

    AutoUpdater:run(self)
end

function onSave()
    return ""
end

function onUpdate()
    data.timePassed = data.timePassed + Time.delta_time
    if data.requestStartupDelay > 0 then
        data.requestStartupDelay = math.max(0, data.requestStartupDelay - Time.delta_time)
    end
    if data.rateLimitCooldown > 0 then
        data.rateLimitCooldown = math.max(0, data.rateLimitCooldown - Time.delta_time)
        PackBuilder.updateRateLimitLabel()
        if data.rateLimitCooldown == 0 then
            data.rateLimitObject = nil
        end
    end
    if data.timePassed >= config.pollInterval then
        data.timePassed = 0
        onUpdateTick()
    end
end

function onUpdateTick()
    if hasDescriptionChanged() then
        updateObject(true)
    end
    if data.requestStartupDelay > 0 then
        return
    end
    PackBuilder.processRequestQueue()
end

function onObjectLeaveContainer(container, leaveObject)
    if container ~= self then
        return
    end

    local setData = setDefinitions[data.setCode]
    if setData and setData.name then
        leaveObject.setName(setData.name .. " Booster (" .. data.setCode .. ")")
        leaveObject.setDescription("SET: " .. data.setCode .. (setData.date and "\nReleased: " .. setData.date or ""))
    else
        leaveObject.setName(data.setCode .. " Booster")
    end

    data.boosterCount = data.boosterCount + 1
    local currentBoosterID = data.boosterCount
    data.requestStartupDelay = math.random() * config.requestStartupJitter
    local packImage = PackBuilder.getPackImage(data.setCode, currentBoosterID)

    leaveObject.createButton {
        label = "generating " .. data.setCode,
        click_function = "noop",
        function_owner = self,
        position = { 0, 0.2, -1.6 },
        rotation = { 0, 0, 0 },
        width = 1000,
        height = 200,
        font_size = 130,
        color = { 0, 0, 0, 95 },
        hover_color = { 0, 0, 0, 95 },
        press_color = { 0, 0, 0, 95 },
        font_color = { 1, 1, 1, 95 },
    }

    leaveObject.createButton {
        label = "building pack",
        click_function = "noop",
        function_owner = self,
        position = { 0, 0.2, 1.6 },
        rotation = { 0, 0, 0 },
        width = 1000,
        height = 200,
        font_size = 130,
        color = { 0, 0, 0, 95 },
        hover_color = { 0, 0, 0, 95 },
        press_color = { 0, 0, 0, 95 },
        font_color = { 1, 1, 1, 95 },
    }

    leaveObject.setLuaScript("function tryObjectEnter() return false end")
    if not PackBuilder.fetchDeckDataFast(currentBoosterID, data.setCode, leaveObject) then
        local baseUrls = BoosterUrls.getSetUrls(data.setCode)
        local urls = PackBuilder.narrowBroadQueries(baseUrls)
        local cacheUrls = PackBuilder.getWarmCacheQueriesFromUrls(baseUrls)
        PackBuilder.fetchDeckData(currentBoosterID, data.setCode, urls, leaveObject, nil, nil, nil, nil, cacheUrls, "set:" .. data.setCode)
    end

    Wait.condition(
            function()
                Wait.condition(function()
                    if leaveObject == null then
                        return
                    end
                    Wait.time(function()
                        if leaveObject == null then
                            return
                        end
                        PackBuilder.spawnGeneratedBooster(leaveObject, PackBuilder.cache[currentBoosterID], packImage)
                    end, config.imageLoadDelay)
                end, function()
                    return leaveObject == null or leaveObject.resting
                end)
            end,
            function()
                return PackBuilder.cache[currentBoosterID] ~= nil
            end
    )
end

function hasDescriptionChanged()
    local description = self.getDescription()
    if description ~= data.lastDescription then
        data.lastDescription = description
        return true
    end
end

function updateObject(allowReload)
    data.setCode = string.upper(self.getDescription()):match("SET:%s*(%S+)") or config.defaultSetCode

    local packImage = PackBuilder.getPackImage(data.setCode, 1)
    if self.getCustomObject().diffuse ~= packImage then
        self.setCustomObject({ diffuse = packImage })
        if allowReload then
            schedulePreviewReload()
        end
    end

    self.clearButtons()
    if packImage == config.defaultPackImage then
        self.createButton({
            label = data.setCode .. " Boosters",
            click_function = "noop",
            function_owner = self,
            position = { 0, 0.2, -1.6 },
            rotation = { 0, 0, 0 },
            width = 1000,
            height = 200,
            font_size = 130,
            color = { 0, 0, 0, 95 },
            hover_color = { 0, 0, 0, 95 },
            press_color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 }
        })
    end
end

function schedulePreviewReload()
    data.reloadToken = data.reloadToken + 1
    local token = data.reloadToken
    Wait.time(function()
        if self ~= null and data.reloadToken == token then
            self.reload()
        end
    end, 1)
end

function spawnSupportedPacks()
    local orderedSetCodes = {}
    for setCode, setData in pairs(setDefinitions) do
        if setData.packImage then
            table.insert(orderedSetCodes, {
                code = setCode,
                name = setData.name,
                date = setData.date,
            })
        end
    end
    table.sort(orderedSetCodes, function(a, b)
        if not a.date then
            return false
        end
        if not b.date then
            return true
        end
        return a.date < b.date
    end)
    local startPos = self.getPosition() + Vector(3, 0, 0)
    local cols, spacingX, spacingZ = 10, 3, 5
    for index, setData in ipairs(orderedSetCodes) do
        Wait.time(function()
            local row = math.floor((index - 1) / cols)
            local col = (index - 1) % cols
            local copy = self.clone({
                position = {
                    x = startPos.x + col * spacingX,
                    y = startPos.y,
                    z = startPos.z - row * spacingZ,
                },
                snap_to_grid = false,
            })
            if setData and setData.name then
                copy.setName(setData.name .. " Booster (" .. setData.code .. ")")
                copy.setDescription("SET: " .. setData.code .. (setData.date and "\nReleased: " .. setData.date or ""))
            else
                copy.setName(setData.code .. " Booster")
            end
        end, (index - 1) * 0.1)
    end
end

function noop()
end

-- Global.getVar('Encoder') -- comment needed to prevent mtg pi table falsely detecting this as a game-crashing or virus-infected object
