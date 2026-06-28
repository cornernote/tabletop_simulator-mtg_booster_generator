-- Bundled by luabundle {"luaVersion":"5.2","version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
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

    local baseUrls = BoosterUrls.getSetUrls(data.setCode)
    local urls = PackBuilder.narrowBroadQueries(baseUrls)
    local cacheUrls = PackBuilder.getWarmCacheQueriesFromUrls(baseUrls)

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
    PackBuilder.fetchDeckData(currentBoosterID, data.setCode, urls, leaveObject, nil, nil, nil, nil, cacheUrls, "set:" .. data.setCode)

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

end)
__bundle_register("set_definitions", function(require, _LOADED, __bundle_register, __bundle_modules)
-----------------------------------------------------------------------
-- SetDefinitions - defines the booster set name, contents, etc
-----------------------------------------------------------------------

local PACK_IMAGE_BASE_URL = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/packs/"

local function packImage(code, variant)
    local lowerCode = string.lower(code)
    if lowerCode == "---" then
        return PACK_IMAGE_BASE_URL .. "---_pack.png"
    end
    if variant then
        return PACK_IMAGE_BASE_URL .. lowerCode .. "-pack-" .. variant .. ".png"
    end
    return PACK_IMAGE_BASE_URL .. lowerCode .. "-pack.png"
end

setDefinitions = {
    TRK = {
        name = "Star Trek",
        date = "2026-11-13",
        getUrls = BoosterUrls.default14CardPack,
    },
    FRA = {
        name = "Reality Fracture",
        date = "2026-10-02",
        getUrls = BoosterUrls.default14CardPack,
    },
    HOB = {
        name = "The Hobbit",
        date = "2026-08-14",
        getUrls = BoosterUrls.default14CardPack,
    },
    MSH = {
        name = "Marvel Super Heroes",
        date = "2026-06-26",
        getUrls = BoosterUrls.default14CardPack,
    },
    SOS = {
        name = "Secrets of Strixhaven",
        date = "2026-04-24",
        getUrls = BoosterUrls.default14CardPack,
    },
    TMT = {
        name = "Teenage Mutant Ninja Turtles",
        date = "2026-03-06",
        getUrls = BoosterUrls.default14CardPack,
    },
    ECL = {
        name = "Lorwyn Eclipsed",
        date = "2026-01-23",
        getUrls = BoosterUrls.default14CardPack,
    },
    TLA = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/18426860329109062848/8608CEB001CF861FC4A6AEB7DEFC99036DDCBC03/",
        name = "Avatar: The Last Airbender",
        date = "2025-11-21",
        getUrls = BoosterUrls.default14CardPack,
    },
    TLAC = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/16172442222396970495/9B571ECCFD4A01EE6287BD6BE1F00D38112F1303/",
        name = "Avatar: The Last Airbender Collector",
        date = "2025-11-21",
        getUrls = function(set)
            return BoosterUrls.default15CardPack({ "TLA", "TLE" })
        end,
    },
    SPM = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/11967831829609287872/6D168435BEFB1C1EE50A4F0B286BF4D8D9FEA7C8/",
        name = "Marvel's Spider-Man",
        date = "2025-09-26",
        getUrls = function(set)
            return BoosterUrls.default14CardPack({ "SPM", "MAR" })
        end,
    },
    SPMC = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/14447519524209323137/A7BC08D5AFE8EB8953D3E6F767C7259CDDAAEB34/",
        name = "Marvel's Spider-Man Collector",
        date = "2025-09-26",
        getUrls = function(set)
            return BoosterUrls.default15CardPack({ "SPM", "MAR", "SPE" })
        end,
    },
    OM1 = {
        name = "Through the Omenpaths",
        date = "2025-09-23",
        getUrls = BoosterUrls.default14CardPack,
    },
    FIN = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/16627771293824374075/C5699273F56C725E5F909A4CF68E0BBB40CB3212/",
        name = "Final Fantasy",
        date = "2025-06-13",
        getUrls = function(set)
            return BoosterUrls.default14CardPack({ "FIN", "FCA" })
        end,
    },
    FINC = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/12474440936943111473/5DD973A1A676B0AF1D27C63CB43CE0B91FD45134/",
        name = "Final Fantasy Collector",
        date = "2025-06-13",
        getUrls = function(set)
            return BoosterUrls.default15CardPack({ "FIN", "FCA", "FIC" })
        end,
    },
    BOK = {
        packImage = "https://i.imgur.com/t6UP7lt.jpg",
        name = "Betrayers of Kamigawa",
        date = "2005-02-04",
        getUrls = function(set)
            local urls = BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
            urls[15] = urls[15]:gsub("r:m", "r:r")
            return urls
        end,
    },
    CHK = {
        packImage = "https://i.imgur.com/E7IW8Tv.jpg",
        name = "Champions of Kamigawa",
        date = "2004-10-01",
    },
    PIO = {
        name = "Pioneer Masters",
        date = "2024-12-10",
        getUrls = BoosterUrls.default14CardPack,
    },
    INR = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33314777894966905/8D9807FCC410A72E23B650DD45417ADE665B4E87/",
        name = "Innistrad Remaster",
        date = "2025-01-24",
        getUrls = BoosterUrls.default14CardPack,
    },
    DFT = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33315411545885589/0C728D0BDFAB373310773FA4546CC4E08B1B11A1/",
        name = "Aetherdrift",
        date = "2025-02-14",
        getUrls = BoosterUrls.default14CardPack,
    },
    EOE = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/15223391781034002798/18D4F50FA52D5739A7AAF47270CD89A8F3161F20/",
        name = "Edge of Eternities",
        date = "2025-08-01",
        getUrls = BoosterUrls.default14CardPack,
    },
    TDM = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33320655968555543/9ADDB19799EBAE44174466FE19E0C52F73EDDAE4/",
        name = "Tarkir: Dragonstorm",
        date = "2025-04-11",
        getUrls = BoosterUrls.default14CardPack,
    },
    FDN = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/14536525535954915931/8D2F0937D979DC3464C145F62E1D7619309396E8/",
        name = "Foundations",
        date = "2024-11-15",
        getUrls = BoosterUrls.default14CardPack,
    },
    J25 = {
        name = "Foundations Jumpstart",
        date = "2024-11-15",
        getUrls = BoosterUrls.default20CardPack,
    },
    DSK = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666215369/BFD6BBAC0DE7F1F5C810F4FFCA8EF5E50EC8A03E/",
        name = "Duskmourn: House of Horror",
        date = "2024-09-27",
        getUrls = BoosterUrls.default14CardPack,
    },
    BLB = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666242938/FA118E357C5820C6BF4EC70CAECC88876B22DE41/",
        name = "Bloomburrow",
        date = "2024-08-02",
        getUrls = BoosterUrls.default14CardPack,
    },
    MB2 = {
        name = "Mystery Booster 2",
        date = "2024-08-02",
        getUrls = BoosterUrls.default15CardPack,
    },
    ACR = {
        name = "Assassin's Creed",
        date = "2024-07-05",
        getUrls = BoosterUrls.beyondBooster,
    },
    MH3 = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666331598/112B58990D8AD19B704448588F6CC34A8BF0E2E9/",
        name = "Modern Horizons III",
        date = "2024-06-14",
        getUrls = BoosterUrls.default14CardPack,
    },
    BIG = {
        name = "The Big Score",
        date = "2024-04-19",
        getUrls = BoosterUrls.default14CardPack,
    },
    MKM = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666403145/D578E8D070D0F89BB866212A8C5FD97AE840F418/",
        name = "Murders at Karlov Manor",
        date = "2024-02-09",
        getUrls = BoosterUrls.default14CardPack,
    },
    OTJ = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666361741/B40E45A8AE490D38D02C8D32295E71920362D781/",
        name = "Outlaws of Thunder Junction",
        date = "2024-04-19",
        getUrls = BoosterUrls.default14CardPack,
    },
    RVR = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/33313055666416970/8B9F38A1D618C5C025C45E8D484B097CA8F245EE/",
        name = "Ravnica Remastered",
        date = "2024-01-12",
        getUrls = function(set)
            return BoosterUrls.swapLandForCommon(BoosterUrls.default14CardPack(set))
        end,
    },
    CLU = {
        name = "Ravnica: Clue Edition",
        date = "2024-02-23",
        getUrls = BoosterUrls.default15CardPack,
    },
    XLN = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/861734852198387392/B81155A30E28760116D166987C221F946D37380E/",
        name = "Ixalan",
        date = "2023-11-17",
    },
    MID = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1734441450308868762/12F6CE09A39E5FEC3B472EBE54562B92A7332027/",
        name = "Innistrad: Midnight Hunt",
        date = "2021-09-24",
        getUrls = function(set)
            local urls = BoosterUrls.default15CardPack(set)
            local transformIndex = math.random(#urls - 1, #urls)
            for i, v in pairs(urls) do
                local add = (i == 7 or (i == transformIndex))
                urls[i] = v .. (add and '+is:transform' or '+-is:transform')
            end
            return urls
        end,
    },
    STX = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1734441184603578733/2009A7D782D40F1456733EFE30ACC064D12B5FFD/",
        name = "StrixHaven",
        date = "2021-04-23",
        getUrls = function(set)
            local urls = {}
            local setQuery = BoosterUrls.makeSetQuery('stx')
            local archiveSetQuery = BoosterUrls.makeSetQuery('sta')
            local mixedSetQuery = BoosterUrls.makeSetQuery({ 'stx', 'sta' })
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 't:land'))
            for c in ('wubrg'):gmatch('.') do
                table.insert(urls, BoosterUrls.makeUrl(setQuery, '-t:basic+r<r+c:' .. c))
            end
            table.insert(urls, BoosterUrls.makeUrl(setQuery, '-t:basic+r<r'))
            table.insert(urls, BoosterUrls.makeUrl(mixedSetQuery, '-t:basic'))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, '-t:basic'))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 't:lesson'))
            table.insert(urls, BoosterUrls.makeUrl(archiveSetQuery, 'r>c+' .. (math.random(2) == 1 and 'lang:en' or 'lang:ja')))
            return urls
        end,
    },
    AFR = {
        name = "Adventures in the Forgotten Realms",
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1734441262522564318/D44434D1C56BA4A590591606A3A50EE4C9F607B8/",
        date = "2021-07-23",
    },
    CMB1 = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1871804141033719694/FE0CC0C11B5ADB27831BAAF0FF37E95852B6F454/",
        name = "Mystery Booster Playtest Cards 2019",
        date = "2019-11-07",
        getUrls = function(set)
            local urls = {}
            local setQuery = BoosterUrls.makeSetQuery('mb1')
            local url = BoosterUrls.makeUrl(setQuery, 's:mb1') -- seems to load s:plst (The List)
            for c in ('wubrg'):gmatch('.') do
                table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r<r+c=' .. c))
                table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r<r+c=' .. c))
            end
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 'c:m+r<r'))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 'c:c+r<r'))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r>=r+frame:2015'))
            table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r>=r+-frame:2015'))
            table.insert(urls, BoosterUrls.makeUrl(BoosterUrls.makeSetQuery('cmb1'), ''))
            return urls
        end,
    },
    UST = {
        packImage = {
            "https://steamusercontent-a.akamaihd.net/ugc/1869553886384090159/B009BD275EAA4E4D327CABF6E9C287FCF974CAE0/",
            "https://steamusercontent-a.akamaihd.net/ugc/1869553886384088312/840D789FDE909D82F2943ADC26138DD838C6D3CD/",
            "https://steamusercontent-a.akamaihd.net/ugc/1869553610271665770/97276A7B7774EF057E915B9A0AB9AC3F81221ED2/",
        },
        name = "Unstable",
        date = "2017-12-08",
    },
    UGL = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1869553610271718076/9F874EFF82054749352677189F63683DC038A17E/",
        name = "Unglued",
        date = "1998-08-11",
    },
    UNH = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1869553610271611558/564F7D6B23A479883C84C4F5D90852CD4C056E9A/",
        name = "Unhinged",
        date = "2004-11-19",
    },
    VOW = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/2027238089146067515/FB7A98B9B0BE5C25098F63981C6C12BBE1036BA6/",
        name = "Innistrad: Crimson Vow",
        date = "2021-11-19",
    },
    UMA = {
        packImage = "https://i.imgur.com/4RylXgU.png",
        name = "Ultimate Masters",
        date = "2018-12-07",
    },
    CMM = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/2093668098031059945/BF91A05DA4A788ED5F5C01B05305F3E4ECE8CE52/",
        name = "Commander Masters",
        date = "2023-08-04",
        getUrls = BoosterUrls.default20CardPack,
    },
    MMA = {
        packImage = "https://i.imgur.com/CU7EL6h.png",
        name = "Modern Masters",
        date = "2013-06-07",
        getUrls = function(set)
            return BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
        end,
    },
    SOK = {
        packImage = "https://i.imgur.com/ctFTHkw.jpg",
        name = "Saviors of Kamigawa",
        date = "2005-06-03",
        getUrls = function(set)
            return BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
        end,
    },
    NEO = {
        packImage = "https://i.imgur.com/5FcGpqC.png",
        name = "Kamigawa: Neon Dynasty",
        date = "2022-02-18",
    },
    DOM = {
        name = "Dominaria",
        date = "2018-04-27",
        getUrls = function(set)
            return BoosterUrls.addCardTypeToPack(BoosterUrls.default15CardPack(set), 't:legendary')
        end,
    },
    WAR = {
        name = "War of the Spark",
        date = "2019-05-03",
        getUrls = function(set)
            return BoosterUrls.addCardTypeToPack(BoosterUrls.default15CardPack(set), 't:planeswalker')
        end,
    },
    ZNR = {
        name = "Zendikar Rising",
        date = "2020-09-25",
        getUrls = function(set)
            return BoosterUrls.addCardTypeToPack(BoosterUrls.default15CardPack(set), 't:land+(is:spell+or+pathway)')
        end,
    },
    CNS = {
        name = "Conspiracy",
        date = "2014-06-06",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-wm:conspiracy', '+wm:conspiracy', 7)
        end,
    },
    CN2 = {
        name = "Conspiracy: Take the Crown",
        date = "2016-08-26",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-wm:conspiracy', '+wm:conspiracy', 7)
        end,
    },
    ISD = {
        name = "Innistrad",
        date = "2011-09-30",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-is:transform', '+is:transform', 7)
        end,
    },
    DKA = {
        name = "Dark Ascension",
        date = "2012-02-03",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-is:transform', '+is:transform', 7)
        end,
    },
    SOI = {
        name = "Shadows over Innistrad",
        date = "2016-04-08",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-is:transform', '+is:transform', 7)
        end,
    },
    EMN = {
        name = "Eldritch Moon",
        date = "2016-07-22",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '+-is:transform', '+is:transform', 7)
        end,
    },
    ICE = {
        name = "Ice Age",
        date = "1995-06-03",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '', '+t:basic+t:snow+unique:prints')
        end,
    },
    ALL = {
        name = "Alliances",
        date = "1996-06-10",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '', '+t:basic+t:snow+unique:prints')
        end,
    },
    CSP = {
        name = "Coldsnap",
        date = "2006-07-21",
        getUrls = function(set)
            local urls = BoosterUrls.default15CardPack(set)
            urls[15] = urls[15]:gsub('r:m', 'r:r')
            return BoosterUrls.createReplacementSlotPack(urls, set, '', 't:basic+t:snow+unique:prints')
        end,
    },
    MH1 = {
        name = "Modern Horizons",
        date = "2019-06-14",
        getUrls = function(set)
            return BoosterUrls.createReplacementSlotPack(BoosterUrls.default15CardPack(set), set, '', '+t:basic+t:snow+unique:prints')
        end,
    },
    KHM = {
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/1734441450301159293/A7F7C010D0312D856CD8667678F5732BDB8F6EB2/",
        name = "Kaldheim",
        date = "2021-02-05",
    },
    LEA = {
        name = "Limited Edition Alpha",
        date = "1993-08-05",
        packImage = "https://steamusercontent-a.akamaihd.net/ugc/11233057164064068203/C3F6F1252903B67720C40A2DBBAE54B3F8F6FD7A/",
        getUrls = function(set)
            return BoosterUrls.alphaCardPack(set)
        end,
    },
}

-- any with names that cannot be lua keys can go below

setDefinitions['???'] = {
    getUrls = function(set)
        return {}
    end,
}

setDefinitions['2XM'] = {
    packImage = "https://steamusercontent-a.akamaihd.net/ugc/2027238089151521799/52EC298FBB89EA2A24DA024981161F96E3522645/",
    name = "Double Masters",
    date = "2020-08-07",
    getUrls = BoosterUrls.default16CardPack,
}

local generatedPackImageCodes = {
    "TRK", "FRA", "HOB", "MSH", "SOS", "TMT", "ECL",
    "TLA", "TLAC", "SPM", "SPMC", "OM1", "FIN", "FINC", "EOE", "TDM", "DFT", "INR",
    "PIO", "FDN", "J25", "DSK", "BLB", "MB2", "ACR", "MH3", "BIG", "OTJ", "CLU", "MKM", "RVR",
    "XLN", "MID", "STX", "AFR", "CMB1", "UGL", "UNH", "VOW", "UMA", "CMM", "MMA",
    "SOK", "NEO", "KHM", "LEA", "2XM", "BOK", "CHK", "DOM", "WAR", "ZNR", "CNS", "CN2",
    "ISD", "DKA", "SOI", "EMN", "ICE", "ALL", "CSP", "MH1",
}

for _, code in ipairs(generatedPackImageCodes) do
    if setDefinitions[code] then
        setDefinitions[code].packImage = packImage(code)
    end
end

setDefinitions['???'].packImage = packImage("---")
setDefinitions.UST.packImage = {
    packImage("UST", 1),
    packImage("UST", 2),
    packImage("UST", 3),
}

return setDefinitions

end)
__bundle_register("pack_builder", function(require, _LOADED, __bundle_register, __bundle_modules)
-----------------------------------------------------------------------
-- PackBuilder - fetches card info and builds a booster pack
-----------------------------------------------------------------------

PackBuilder = {}

PackBuilder.cache = {}
PackBuilder.sharedQueryCacheName = "AnyMtgBoosterGeneratorQueryCaches"
PackBuilder.sharedEmptyQueryCacheName = "AnyMtgBoosterGeneratorEmptyQueryCaches"

PackBuilder.enqueueRequest = function(url, callback, position)
    local entry = { url = url, callback = callback }
    if position == "start" then
        table.insert(data.requestQueue, 1, entry)
    else
        table.insert(data.requestQueue, entry)
    end
end

PackBuilder.startRateLimitCooldown = function(url, callback, leaveObject)
    data.rateLimitCooldown = config.rateLimitDelay
    data.rateLimitObject = leaveObject
    PackBuilder.enqueueRequest(url, callback, "start")
    PackBuilder.updateRateLimitLabel()
end

PackBuilder.updateRateLimitLabel = function()
    local leaveObject = data.rateLimitObject
    if leaveObject then
        PackBuilder.editStatusButton(leaveObject, "waiting: " .. math.ceil(data.rateLimitCooldown) .. "s")
    end
end

PackBuilder.editStatusButton = function(object, label)
    if object == null then
        return
    end
    pcall(function()
        object.editButton({ index = 1, label = label })
    end)
end

PackBuilder.printDebug = function(message)
    if printAll then
        printAll("Any MTG Booster Generator: " .. message)
    else
        print("Any MTG Booster Generator: " .. message)
    end
end

PackBuilder.processRequestQueue = function()
    if #data.requestQueue == 0 or data.rateLimitCooldown > 0 then
        return
    end
    local request = table.remove(data.requestQueue, 1)
    local headers = {
        ['User-Agent'] = AutoUpdater.name .. '/' .. AutoUpdater.version,
        ['Accept'] = 'application/json'
    }
    WebRequest.custom(request.url, "GET", true, nil, headers, request.callback)
end

PackBuilder.isRateLimitedResponse = function(response)
    if response.response_code == 429 then
        return true
    end
    if not response.text then
        return false
    end
    local text = response.text:lower()
    return text:find("rate-limited", 1, true) ~= nil or text:find('"code":"rate_limit"', 1, true) ~= nil
end

PackBuilder.isEmptyQueryResponse = function(response)
    if response.response_code ~= 404 or not response.text then
        return false
    end
    local text = response.text:lower()
    return text:find('"code":"not_found"', 1, true) ~= nil
            or text:find("no cards found", 1, true) ~= nil
end

PackBuilder.mergeTables = function(target, source)
    if type(source) ~= "table" then
        return target
    end
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = value
        end
    end
    return target
end

PackBuilder.getSharedQueryCaches = function()
    if not Global then
        return nil
    end
    local ok, shared = pcall(function()
        return Global.getTable(PackBuilder.sharedQueryCacheName)
    end)
    if ok and type(shared) == "table" then
        return shared
    end
    return nil
end

PackBuilder.getSharedEmptyQueryCaches = function()
    if not Global then
        return nil
    end
    local ok, shared = pcall(function()
        return Global.getTable(PackBuilder.sharedEmptyQueryCacheName)
    end)
    if ok and type(shared) == "table" then
        return shared
    end
    return nil
end

PackBuilder.publishSharedQueryCaches = function()
    if not Global then
        return
    end
    pcall(function()
        Global.setTable(PackBuilder.sharedQueryCacheName, data.queryCaches)
        Global.setTable(PackBuilder.sharedEmptyQueryCacheName, data.emptyQueryCaches)
    end)
end

PackBuilder.refreshSharedQueryCaches = function()
    local shared = PackBuilder.getSharedQueryCaches()
    if shared then
        PackBuilder.mergeTables(data.queryCaches, shared)
    end
    local sharedEmpty = PackBuilder.getSharedEmptyQueryCaches()
    if sharedEmpty then
        PackBuilder.mergeTables(data.emptyQueryCaches, sharedEmpty)
    end
end

PackBuilder.bindSharedQueryCaches = function(savedQueryCaches)
    data.queryCaches = data.queryCaches or {}
    data.emptyQueryCaches = data.emptyQueryCaches or {}
    PackBuilder.mergeTables(data.queryCaches, savedQueryCaches)
    PackBuilder.refreshSharedQueryCaches()
    PackBuilder.publishSharedQueryCaches()
end

PackBuilder.hasQueryCache = function(query)
    return data.queryCaches[query] ~= nil or data.emptyQueryCaches[query] == true
end

PackBuilder.extractQuery = function(url)
    local query = (url:gsub("^" .. config.apiBaseURL:gsub("([^%w])", "%%%1"), ""))
    return PackBuilder.normalizeQuery(query)
end

PackBuilder.normalizeQuery = function(query)
    query = query:gsub("^r:c$", "r:common")
    query = query:gsub("^r:c%+", "r:common+")
    query = query:gsub("%+r:c%+", "+r:common+")
    query = query:gsub("%+r:c$", "+r:common")
    return query
end

PackBuilder.extractSetCodes = function(query)
    local codes, seen = {}, {}
    local function add(code)
        code = string.upper(code)
        if not seen[code] then
            seen[code] = true
            table.insert(codes, code)
        end
    end
    for code in query:gmatch("set:([%w]+)") do
        add(code)
    end
    for code in query:gmatch("[^%a]s:([%w]+)") do
        add(code)
    end
    for code in query:gmatch("^s:([%w]+)") do
        add(code)
    end
    return codes
end

PackBuilder.fetchSetPage = function(setCode, url, loadState)
    local function handleResponse(request)
        if PackBuilder.isRateLimitedResponse(request) then
            PackBuilder.startRateLimitCooldown(url, handleResponse, loadState.leaveObject)
            return
        end

        if request.response_code == 200 then
            local page = JSON.decode(request.text)
            if page and page.data then
                PackBuilder.compactCardsAsync(page.data, loadState, function()
                    if page and page.has_more and page.next_page then
                        PackBuilder.fetchSetPage(setCode, page.next_page, loadState)
                        return
                    end
                    PackBuilder.finishSetCacheLoad(setCode, loadState)
                end)
                return
            end
        elseif PackBuilder.isEmptyQueryResponse(request) then
            loadState.empty = true
        else
            local errorInfo = request.text and JSON.decode(request.text)
            loadState.error = errorInfo and errorInfo.details or (request.error .. ": " .. tostring(request.text))
        end

        PackBuilder.finishSetCacheLoad(setCode, loadState)
    end

    PackBuilder.enqueueRequest(url, handleResponse, "end")
end

PackBuilder.queryToSearchUrl = function(query)
    return config.searchBaseURL .. PackBuilder.urlEncode(query:gsub("%+", " "))
end

PackBuilder.fetchQueryPage = function(query, url, loadState)
    local function handleResponse(request)
        if PackBuilder.isRateLimitedResponse(request) then
            PackBuilder.startRateLimitCooldown(url, handleResponse, loadState.leaveObject)
            return
        end

        if request.response_code == 200 then
            local page = JSON.decode(request.text)
            if page and page.data then
                PackBuilder.compactCardsAsync(page.data, loadState, function()
                    if page and page.has_more and page.next_page then
                        PackBuilder.fetchQueryPage(query, page.next_page, loadState)
                        return
                    end
                    PackBuilder.finishQueryCacheLoad(query, loadState)
                end)
                return
            end
        else
            local errorInfo = request.text and JSON.decode(request.text)
            loadState.error = errorInfo and errorInfo.details or (request.error .. ": " .. tostring(request.text))
        end

        PackBuilder.finishQueryCacheLoad(query, loadState)
    end

    PackBuilder.enqueueRequest(url, handleResponse, "end")
end

PackBuilder.finishQueryCacheLoad = function(query, loadState)
    if #loadState.cards == 0 then
        data.emptyQueryCaches[query] = true
        PackBuilder.printDebug("cached empty query: " .. query)
    else
        data.queryCaches[query] = loadState.cards
        data.emptyQueryCaches[query] = nil
        PackBuilder.printDebug("cached query: " .. query .. " (" .. #loadState.cards .. " cards)")
    end
    PackBuilder.publishSharedQueryCaches()
    data.queryCacheLoads[query] = nil
    for _, callback in ipairs(loadState.callbacks) do
        callback(nil)
    end
end

PackBuilder.compactCardsAsync = function(cards, loadState, done)
    local index = 1
    local function processChunk()
        local last = math.min(#cards, index + config.cacheChunkSize - 1)
        for i = index, last do
            table.insert(loadState.cards, PackBuilder.compactCard(cards[i]))
        end
        index = last + 1
        if index <= #cards then
            Wait.time(processChunk, 0.01)
        else
            done()
        end
    end
    processChunk()
end

PackBuilder.finishSetCacheLoad = function(setCode, loadState)
    if not loadState.error then
        data.setCaches[setCode] = loadState.cards
    end
    data.setCacheLoads[setCode] = nil
    for _, callback in ipairs(loadState.callbacks) do
        callback(loadState.error)
    end
end

PackBuilder.compactCardFace = function(face)
    return {
        name = face.name,
        type_line = face.type_line,
        cmc = face.cmc,
        oracle_text = face.oracle_text,
        power = face.power,
        toughness = face.toughness,
        loyalty = face.loyalty,
        image_uris = face.image_uris,
    }
end

PackBuilder.compactCard = function(card)
    local compact = {
        name = card.name,
        type_line = card.type_line,
        cmc = card.cmc,
        oracle_text = card.oracle_text,
        power = card.power,
        toughness = card.toughness,
        loyalty = card.loyalty,
        oracle_id = card.oracle_id,
        image_uris = card.image_uris,
        colors = card.colors,
        rarity = card.rarity,
        layout = card.layout,
        watermark = card.watermark,
        frame = card.frame,
        lang = card.lang,
    }
    if card.card_faces then
        compact.card_faces = {}
        for _, face in ipairs(card.card_faces) do
            table.insert(compact.card_faces, PackBuilder.compactCardFace(face))
        end
    end
    return compact
end

PackBuilder.loadSetCache = function(setCode, leaveObject, callback)
    if data.setCaches[setCode] then
        callback()
        return
    end

    local loadState = data.setCacheLoads[setCode]
    if loadState then
        table.insert(loadState.callbacks, callback)
        return
    end

    loadState = {
        cards = {},
        callbacks = { callback },
        leaveObject = leaveObject,
        cacheEmptyOnError = true,
    }
    data.setCacheLoads[setCode] = loadState
    local url = config.searchBaseURL .. PackBuilder.urlEncode("set:" .. setCode)
    PackBuilder.fetchSetPage(setCode, url, loadState)
end

PackBuilder.ensureSetCaches = function(urls, leaveObject, callback)
    local needed, seen = {}, {}
    for _, url in ipairs(urls) do
        for _, setCode in ipairs(PackBuilder.extractSetCodes(PackBuilder.extractQuery(url))) do
            if not seen[setCode] and not data.setCaches[setCode] then
                seen[setCode] = true
                table.insert(needed, setCode)
            end
        end
    end

    if #needed == 0 then
        callback({})
        return
    end

    if #needed == 1 then
        PackBuilder.printDebug("fetching cache 1/1: " .. needed[1])
    else
        PackBuilder.printDebug("fetching cache " .. #needed .. " queries")
    end

    local remaining = #needed
    local errors = {}
    for _, setCode in ipairs(needed) do
        if leaveObject then
            PackBuilder.editStatusButton(leaveObject, "caching")
        end
        PackBuilder.loadSetCache(setCode, leaveObject, function(error)
            if error then
                table.insert(errors, { url = setCode, message = error })
            end
            remaining = remaining - 1
            if leaveObject and remaining > 0 then
                PackBuilder.editStatusButton(leaveObject, "caching")
            end
            if remaining == 0 then
                callback(errors)
            end
        end)
    end
end

PackBuilder.loadQueryCache = function(query, leaveObject, callback)
    if PackBuilder.hasQueryCache(query) then
        callback()
        return
    end

    local loadState = data.queryCacheLoads[query]
    if loadState then
        table.insert(loadState.callbacks, callback)
        return
    end

    loadState = {
        cards = {},
        callbacks = { callback },
        leaveObject = leaveObject,
    }
    data.queryCacheLoads[query] = loadState
    PackBuilder.fetchQueryPage(query, PackBuilder.queryToSearchUrl(query), loadState)
end

PackBuilder.ensureQueryCaches = function(urls, leaveObject, callback, jobKey)
    PackBuilder.refreshSharedQueryCaches()

    local requested, requestedSeen = {}, {}
    for _, url in ipairs(urls) do
        local query = PackBuilder.extractQuery(url)
        if not requestedSeen[query] then
            requestedSeen[query] = true
            table.insert(requested, query)
        end
    end

    jobKey = jobKey or table.concat(requested, "\n")
    local existingJob = data.cacheJobs[jobKey]
    if existingJob then
        table.insert(existingJob.callbacks, callback)
        PackBuilder.editStatusButton(leaveObject, "waiting cache")
        return
    end

    local needed, seen = {}, {}
    for _, query in ipairs(requested) do
        if not seen[query] and not PackBuilder.hasQueryCache(query) then
            seen[query] = true
            table.insert(needed, query)
        end
    end

    if #needed == 0 then
        callback({})
        return
    end

    local total = #needed
    local completed = 0
    local remaining = total
    local errors = {}
    data.cacheJobs[jobKey] = { callbacks = { callback } }
    if total == 1 then
        PackBuilder.editStatusButton(leaveObject, "caching 1/1")
    else
        PackBuilder.editStatusButton(leaveObject, "caching 1/" .. total)
    end
    for _, query in ipairs(needed) do
        PackBuilder.loadQueryCache(query, leaveObject, function(error)
            if error then
                table.insert(errors, { url = query, message = error })
            end
            completed = completed + 1
            remaining = remaining - 1
            if remaining > 0 then
                PackBuilder.editStatusButton(leaveObject, "caching " .. (completed + 1) .. "/" .. total)
            end
            if remaining == 0 then
                local job = data.cacheJobs[jobKey]
                data.cacheJobs[jobKey] = nil
                for _, jobCallback in ipairs(job and job.callbacks or { callback }) do
                    jobCallback(errors)
                end
            end
        end)
    end
end

PackBuilder.narrowBroadQueries = function(urls)
    local narrowed = {}
    for _, url in ipairs(urls) do
        table.insert(narrowed, PackBuilder.narrowBroadQuery(url))
    end
    return narrowed
end

PackBuilder.narrowBroadQuery = function(url)
    if not PackBuilder.shouldNarrowBroadQuery(url) then
        return url
    end

    local buckets = PackBuilder.getBroadQueryBuckets()
    return url .. "+" .. buckets[math.random(1, #buckets)]
end

PackBuilder.shouldNarrowBroadQuery = function(url)
    local query = PackBuilder.extractQuery(url)
    local filterQuery = query:gsub("set:[%w]+", ""):gsub("s:[%w]+", "")
    local hasColorFilter = filterQuery:find("c[>:]=?[wubrg]", 1) ~= nil
            or filterQuery:find("c:[wubrgcm]", 1) ~= nil
            or filterQuery:find("c=[wubrg]", 1) ~= nil
    local hasBroadRarity = filterQuery:find("r:common", 1, true) ~= nil
            or filterQuery:find("r:u", 1, true) ~= nil
            or filterQuery:find("r:r", 1, true) ~= nil
            or filterQuery:find("r:m", 1, true) ~= nil
            or filterQuery:find("r>=r", 1, true) ~= nil
            or filterQuery:find("r<r", 1, true) ~= nil

    local positiveTypeQuery = filterQuery:gsub("%-t:[%w]+", ""):gsub("%-%(t:[%w]+%)", "")
    return not hasColorFilter and hasBroadRarity and not positiveTypeQuery:find("t:basic", 1, true)
end

PackBuilder.getBroadQueryBuckets = function()
    return { "c>=w", "c>=u", "c>=b", "c>=r", "c>=g", "c:c+t:creature", "c:c+-t:creature" }
end

PackBuilder.getWarmCacheQueries = function(setCode)
    return PackBuilder.getWarmCacheQueriesFromUrls(BoosterUrls.getSetUrls(setCode))
end

PackBuilder.getWarmCacheQueriesFromUrls = function(urls)
    local queries, seen = {}, {}
    local function add(query)
        if not seen[query] then
            seen[query] = true
            table.insert(queries, query)
        end
    end

    for _, url in ipairs(urls) do
        for _, warmUrl in ipairs(PackBuilder.getWarmAlternateUrls(url)) do
            if PackBuilder.shouldNarrowBroadQuery(warmUrl) then
                for _, bucket in ipairs(PackBuilder.getBroadQueryBuckets()) do
                    add(PackBuilder.extractQuery(warmUrl .. "+" .. bucket))
                end
            else
                add(PackBuilder.extractQuery(warmUrl))
            end
        end
    end
    return queries
end

PackBuilder.getWarmAlternateUrls = function(url)
    local alternates, seen = {}, {}
    local function add(candidate)
        if not seen[candidate] then
            seen[candidate] = true
            table.insert(alternates, candidate)
        end
    end

    add(url)
    local index = 1
    while index <= #alternates do
        local current = alternates[index]
        for _, alternateUrl in ipairs(PackBuilder.getRarityAlternateUrls(current)) do
            add(alternateUrl)
        end
        for _, alternateUrl in ipairs(PackBuilder.getTransformAlternateUrls(current)) do
            add(alternateUrl)
        end
        for _, alternateUrl in ipairs(PackBuilder.getLanguageAlternateUrls(current)) do
            add(alternateUrl)
        end
        index = index + 1
    end
    return alternates
end

PackBuilder.getTransformAlternateUrls = function(url)
    local alternates = {}
    if url:find("%+%-is:transform") then
        table.insert(alternates, (url:gsub("%+%-is:transform", "+is:transform")))
    elseif url:find("%+is:transform") then
        table.insert(alternates, (url:gsub("%+is:transform", "+-is:transform")))
    end
    return alternates
end

PackBuilder.getLanguageAlternateUrls = function(url)
    local alternates = {}
    if url:find("%+lang:en") then
        table.insert(alternates, (url:gsub("%+lang:en", "+lang:ja")))
    elseif url:find("%+lang:ja") then
        table.insert(alternates, (url:gsub("%+lang:ja", "+lang:en")))
    end
    return alternates
end

PackBuilder.getRarityAlternateUrls = function(url)
    local alternates = {}
    if url:find("r:r", 1, true) then
        table.insert(alternates, (url:gsub("r:r", "r:m")))
    elseif url:find("r:m", 1, true) then
        table.insert(alternates, (url:gsub("r:m", "r:r")))
    end
    return alternates
end

PackBuilder.cardHasType = function(card, typeName)
    local typeLine = string.lower(card.type_line or "")
    return typeLine:find(string.lower(typeName), 1, true) ~= nil
end

PackBuilder.cardHasColor = function(card, color)
    local colors = card.colors or {}
    color = string.upper(color)
    for _, cardColor in ipairs(colors) do
        if string.upper(cardColor) == color then
            return true
        end
    end
    return false
end

PackBuilder.cardColorCount = function(card)
    return #(card.colors or {})
end

PackBuilder.cardMatchesLocalQuery = function(card, query)
    query = query:lower()
    local filterQuery = query:gsub("set:[%w]+", ""):gsub("s:[%w]+", "")
    local rarityRank = { common = 1, uncommon = 2, rare = 3, mythic = 4 }
    local rarityCode = { c = "common", common = "common", u = "uncommon", uncommon = "uncommon", r = "rare", rare = "rare", m = "mythic", mythic = "mythic" }
    local rank = rarityRank[card.rarity or ""] or 0

    for code in filterQuery:gmatch("r:([%w]+)") do
        if card.rarity ~= rarityCode[code] then
            return false
        end
    end
    for op, code in filterQuery:gmatch("r([<>]=?)([%w]+)") do
        local target = rarityRank[rarityCode[code]] or 0
        if op == "<" and not (rank < target) then return false end
        if op == "<=" and not (rank <= target) then return false end
        if op == ">" and not (rank > target) then return false end
        if op == ">=" and not (rank >= target) then return false end
    end

    for typeName in filterQuery:gmatch("%-t:([%w]+)") do
        if PackBuilder.cardHasType(card, typeName) then
            return false
        end
    end
    for typeName in filterQuery:gmatch("%-%(t:([%w]+)%)") do
        if PackBuilder.cardHasType(card, typeName) then
            return false
        end
    end
    local positiveQuery = filterQuery:gsub("%-t:[%w]+", ""):gsub("%-%(t:[%w]+%)", "")
    for typeName in positiveQuery:gmatch("t:([%w]+)") do
        if not PackBuilder.cardHasType(card, typeName) then
            return false
        end
    end

    for color in filterQuery:gmatch("c>=([wubrg])") do
        if not PackBuilder.cardHasColor(card, color) then
            return false
        end
    end
    for color in filterQuery:gmatch("c:([wubrg])") do
        if not PackBuilder.cardHasColor(card, color) then
            return false
        end
    end
    for color in filterQuery:gmatch("c=([wubrg])") do
        if PackBuilder.cardColorCount(card) ~= 1 or not PackBuilder.cardHasColor(card, color) then
            return false
        end
    end
    if filterQuery:find("c:m", 1, true) and PackBuilder.cardColorCount(card) < 2 then
        return false
    end
    if filterQuery:find("c:c", 1, true) and PackBuilder.cardColorCount(card) ~= 0 then
        return false
    end

    local positiveSpecialQuery = filterQuery
            :gsub("%-is:transform", "")
            :gsub("%-wm:conspiracy", "")
            :gsub("%-frame:2015", "")

    if positiveSpecialQuery:find("is:transform", 1, true) and card.layout ~= "transform" then
        return false
    end
    if filterQuery:find("-is:transform", 1, true) and card.layout == "transform" then
        return false
    end
    if positiveSpecialQuery:find("wm:conspiracy", 1, true) and card.watermark ~= "conspiracy" then
        return false
    end
    if filterQuery:find("-wm:conspiracy", 1, true) and card.watermark == "conspiracy" then
        return false
    end
    if positiveSpecialQuery:find("frame:2015", 1, true) and tostring(card.frame) ~= "2015" then
        return false
    end
    if filterQuery:find("-frame:2015", 1, true) and tostring(card.frame) == "2015" then
        return false
    end
    for lang in filterQuery:gmatch("lang:([%w]+)") do
        if card.lang ~= lang then
            return false
        end
    end

    return true
end

PackBuilder.getCachedCandidates = function(url)
    local query = PackBuilder.extractQuery(url)
    if data.queryCaches[query] then
        return data.queryCaches[query]
    end
    if data.emptyQueryCaches[query] then
        return {}
    end

    local candidates = {}
    for _, setCode in ipairs(PackBuilder.extractSetCodes(query)) do
        for _, card in ipairs(data.setCaches[setCode] or {}) do
            if PackBuilder.cardMatchesLocalQuery(card, query) then
                table.insert(candidates, card)
            end
        end
    end
    return candidates
end

PackBuilder.chooseCachedCard = function(url, seenNames)
    local candidates = PackBuilder.getCachedCandidates(url)
    if #candidates == 0 then
        return nil
    end

    local unseen = {}
    for _, card in ipairs(candidates) do
        if not seenNames[card.name] then
            table.insert(unseen, card)
        end
    end
    if #unseen > 0 then
        candidates = unseen
    end
    return candidates[math.random(1, #candidates)]
end

PackBuilder.fetchDeckData = function(boosterID, setCode, urls, leaveObject, attempts, existingDeck, replaceIndices, originalUrls, cacheUrls, cacheJobKey)
    if not existingDeck then
        PackBuilder.ensureQueryCaches(cacheUrls or urls, leaveObject, function()
            local deck = {
                Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 180, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
                Name = "Deck",
                Nickname = setCode .. " Booster",
                DeckIDs = {},
                CustomDeck = {},
                ContainedObjects = {},
            }
            local seenNames = {}
            local requestErrors = {}

            for i, url in ipairs(urls) do
                local card = PackBuilder.chooseCachedCard(url, seenNames)
                if card then
                    seenNames[card.name] = true
                    local cardData = PackBuilder.createCardData(card, i)
                    deck.ContainedObjects[i] = cardData
                    deck.DeckIDs[i] = cardData.CardID
                    deck.CustomDeck[i] = cardData.CustomDeck[i]
                else
                    table.insert(requestErrors, { url = url, message = "No cached Scryfall cards matched this booster slot." })
                end
            end

            local boosterContents = {}
            if setCode == config.defaultSetCode then
                table.insert(boosterContents, PackBuilder.generateInstructionNotecard())
            else
                table.insert(boosterContents, deck)
            end

            for _, error in ipairs(requestErrors) do
                table.insert(boosterContents, PackBuilder.generateErrorNotecard(error))
            end

            PackBuilder.cache[boosterID] = boosterContents
        end, cacheJobKey)
        return
    end

    attempts = attempts or 0
    originalUrls = originalUrls or urls
    local deck = existingDeck or {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 180, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
        Name = "Deck",
        Nickname = setCode .. " Booster",
        DeckIDs = {},
        CustomDeck = {},
        ContainedObjects = {},
    }

    local requestsPending = #urls
    local requestsCompleted = 0
    local requestErrors = {}

    for j, url in ipairs(urls) do
        local i = replaceIndices and replaceIndices[j] or j
        local handleResponse
        handleResponse = function(request)
            if PackBuilder.isRateLimitedResponse(request) then
                PackBuilder.startRateLimitCooldown(url, handleResponse, leaveObject)
                return
            end
            if request.response_code == 200 then
                local cardData = PackBuilder.createCardDataFromJSON(request.text, i)
                if cardData then
                    deck.ContainedObjects[i] = cardData
                    deck.DeckIDs[i] = cardData.CardID
                    deck.CustomDeck[i] = cardData.CustomDeck[i]
                end
            else
                local errorInfo = JSON.decode(request.text)
                local message = errorInfo and errorInfo.details or (request.error .. ": " .. request.text)
                table.insert(requestErrors, { url = url, message = message })
            end
            requestsCompleted = requestsCompleted + 1
            if leaveObject then
                PackBuilder.editStatusButton(leaveObject, attempts > 0 and "deduping" or "building pack")
            end
        end
        PackBuilder.enqueueRequest(url, handleResponse, existingDeck and "start" or "end")
    end

    Wait.condition(function()
        if leaveObject == null then
            return
        end
        local seen, dupes = {}, {}
        for i, card in ipairs(deck.ContainedObjects) do
            if card then
                if seen[card.Nickname] then
                    table.insert(dupes, i)
                else
                    seen[card.Nickname] = true
                end
            end
        end
        if #dupes > 0 then
            local dupeUrls = {}
            for _, i in ipairs(dupes) do
                table.insert(dupeUrls, originalUrls[i])
            end
            Wait.time(function()
                PackBuilder.fetchDeckData(boosterID, setCode, dupeUrls, leaveObject, attempts + 1, deck, dupes, originalUrls)
            end, 0.1)
        else
            local boosterContents = {}
            if setCode == config.defaultSetCode then
                table.insert(boosterContents, PackBuilder.generateInstructionNotecard())
            else
                table.insert(boosterContents, deck)
            end

            for _, error in ipairs(requestErrors) do
                table.insert(boosterContents, PackBuilder.generateErrorNotecard(error))
            end

            PackBuilder.cache[boosterID] = boosterContents
        end
    end, function()
        return requestsPending == requestsCompleted
    end)
end

PackBuilder.generateErrorNotecard = function(error)
    return {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
        Name = "Notecard",
        Nickname = "Booster Generation Error",
        Description = "url: " .. error.url .. "\n\n" .. error.message,
        Grid = false, Snap = false
    }
end

PackBuilder.copyTable = function(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = PackBuilder.copyTable(child)
    end
    return copy
end

PackBuilder.spawnGeneratedBooster = function(leaveObject, boosterContents, packImage)
    if leaveObject == null then
        return
    end

    local objectData = leaveObject.getData()
    leaveObject.destruct()
    objectData.GUID = nil
    if packImage and objectData.CustomMesh then
        objectData.CustomMesh = PackBuilder.copyTable(objectData.CustomMesh)
        objectData.CustomMesh.DiffuseURL = packImage
    end
    objectData.ContainedObjects = boosterContents
    objectData.LuaScript = packLua
    local generatedBooster = spawnObjectData({ data = objectData })
    PackBuilder.activateGeneratedBooster(generatedBooster, true)
end

PackBuilder.finishSequentialDeck = function(generatedBooster, deck)
    if generatedBooster == null then
        return
    end

    local deckObject = spawnObjectData({ data = deck })
    Wait.time(function()
        if generatedBooster == null or deckObject == null then
            return
        end
        pcall(function()
            generatedBooster.putObject(deckObject)
        end)
        PackBuilder.activateGeneratedBooster(generatedBooster)
    end, 0.1)
end

PackBuilder.activateGeneratedBooster = function(generatedBooster, scriptAlreadySet)
    if generatedBooster == null then
        return
    end
    if scriptAlreadySet then
        return
    end
    generatedBooster.setLuaScript(packLua)
    Wait.time(function()
        if generatedBooster ~= null then
            generatedBooster.reload()
        end
    end, 0.1)
end

PackBuilder.createGeneratedBoosterProgressButton = function(generatedBooster, label)
    if generatedBooster == null then
        return
    end
    generatedBooster.createButton {
        label = label,
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
end

PackBuilder.setGeneratedBoosterProgress = function(generatedBooster, label)
    if generatedBooster == null then
        return
    end
    pcall(function()
        generatedBooster.editButton({ index = 0, label = label })
    end)
end

PackBuilder.generateInstructionNotecard = function()
    local setsWithPackImages = {}
    for code, setData in pairs(setDefinitions) do
        if setData.packImage then
            table.insert(setsWithPackImages, code)
        end
    end
    return {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1, },
        Name = "Notecard",
        Nickname = 'REPLACE "SET: ???" IN BOX DESCRIPTION',
        Description = "\nAlmost all sets are supported, see:"
                .. "\nhttps://scryfall.com/sets"
                .. "\n"
                .. "\nCustom pack images are available for:"
                .. "\n" .. table.concat(setsWithPackImages, ", "),
        Grid = false, Snap = false
    }
end

PackBuilder.createCardDataFromJSON = function(jsonString, cardIndex)
    local card = JSON.decode(jsonString)
    if not card or not card.name then
        error("Failed to decode JSON: " .. jsonString)
        return
    end
    return PackBuilder.createCardData(card, cardIndex)
end

PackBuilder.createCardData = function(card, cardIndex)
    local cardName, cardOracle, faceURL, backData

    if card.card_faces then
        if card.image_uris then
            cardName = PackBuilder.formattedName(card.card_faces[1])
            cardOracle = ""
            for i, face in ipairs(card.card_faces) do
                cardOracle = cardOracle .. PackBuilder.formattedName(face) .. '\n' .. PackBuilder.getCardOracleText(face)
                if i < #card.card_faces then
                    cardOracle = cardOracle .. '\n'
                end
            end
            faceURL = PackBuilder.getImageUrl(card)
        else
            local face, back = card.card_faces[1], card.card_faces[2]
            cardName = PackBuilder.formattedName(face, 'DFC')
            cardOracle = PackBuilder.getCardOracleText(face)
            faceURL = PackBuilder.getImageUrl(face)
            local backURL = PackBuilder.getImageUrl(back)
            local backCardIndex = cardIndex + 100
            backData = {
                Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
                Name = "Card",
                Nickname = PackBuilder.formattedName(back, 'DFC'),
                Description = PackBuilder.getCardOracleText(back),
                Memo = card.oracle_id,
                CardID = backCardIndex * 100,
                CustomDeck = {
                    [backCardIndex] = {
                        FaceURL = backURL, BackURL = config.backURL, NumWidth = 1, NumHeight = 1,
                        Type = 0, BackIsHidden = true, UniqueBack = false
                    }
                }
            }
        end
    else
        cardName = PackBuilder.formattedName(card)
        cardOracle = PackBuilder.getCardOracleText(card)
        faceURL = PackBuilder.getImageUrl(card)
    end

    local cardData = {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
        Name = "Card",
        Nickname = cardName,
        Description = cardOracle,
        Memo = card.oracle_id,
        CardID = cardIndex * 100,
        CustomDeck = {
            [cardIndex] = {
                FaceURL = faceURL, BackURL = config.backURL, NumWidth = 1, NumHeight = 1,
                Type = 0, BackIsHidden = true, UniqueBack = false
            }
        }
    }

    if backData then
        cardData.States = { [2] = backData }
    end
    return cardData
end

PackBuilder.getImageUrl = function(card)
    local imageUris = card.image_uris or {}
    local url = imageUris.normal or imageUris.large or imageUris.png
    if not url then
        return nil
    end
    return PackBuilder.proxiedImageUrl(url:gsub('%?.*', ''))
end

PackBuilder.proxiedImageUrl = function(url)
    if url:find("cards.scryfall.io", 1, true) then
        return config.imageProxyBaseURL .. PackBuilder.urlEncode(url) .. "&output=jpg"
    end
    return url
end

PackBuilder.urlEncode = function(value)
    return tostring(value):gsub("([^%w%-_%.~])", function(character)
        return string.format("%%%02X", string.byte(character))
    end)
end

PackBuilder.formattedName = function(face, typeSuffix)
    return string.format(
            '%s\n%s %s CMC %s',
            face.name:gsub('"', ''),
            face.type_line,
            tostring(face.cmc or 0),
            typeSuffix or ""
    )            :gsub('%s$', '')
end

PackBuilder.getCardOracleText = function(cardFace)
    local powerToughness = ""
    if cardFace.power then
        powerToughness = '\n[b]' .. cardFace.power .. '/' .. cardFace.toughness .. '[b]'
    elseif cardFace.loyalty then
        powerToughness = '\n[b]' .. tostring(cardFace.loyalty) .. '[/b]'
    end
    return (cardFace.oracle_text or "") .. powerToughness
end

PackBuilder.getPackImage = function(setCode, index)
    local packImage = setDefinitions[setCode] and setDefinitions[setCode].packImage or config.defaultPackImage
    if type(packImage) == "table" then
        index = index or 1
        packImage = packImage[((index - 1) % #packImage) + 1]
    end
    return packImage
end

PackBuilder.getRandomPackImage = function(setCode)
    return PackBuilder.getPackImage(setCode, math.random(1, 1000000))
end

return PackBuilder

end)
__bundle_register("booster_urls", function(require, _LOADED, __bundle_register, __bundle_modules)
-----------------------------------------------------------------------
-- BoosterUrls - builds URL lists for set types
-----------------------------------------------------------------------

BoosterUrls = { }

BoosterUrls.randomRarity = function(mythicChance, rareChance, uncommonChance)
    if math.random(1, mythicChance or 36) == 1 then
        return 'r:m'
    elseif math.random(1, rareChance or 8) == 1 then
        return 'r:r'
    elseif math.random(1, uncommonChance or 4) == 1 then
        return 'r:u'
    else
        return 'r:c'
    end
end

BoosterUrls.chooseMasterpieceReplacement = function(sets, urls)
    if type(sets) == "string" then
        sets = { sets }
    end

    local masterpieceSets = {
        bfz = 'exp',
        ogw = 'exp',
        kld = 'mps',
        aer = 'mps',
        akh = 'mp2',
        hou = 'mp2',
        stx = 'sta',
        tsp = 'tsb',
        mb1 = 'fmb1',
        mh2 = 'h1r',
    }

    for _, set in ipairs(sets) do
        local masterpieceSet = masterpieceSets[set]
        if masterpieceSet and math.random(1, 144) == 1 then
            urls[#urls] = BoosterUrls.makeUrl(BoosterUrls.makeSetQuery(masterpieceSet))
        end
    end
end

BoosterUrls.makeSetQuery = function(sets)
    if type(sets) == "string" then
        sets = { sets }
    end

    if #sets > 1 then
        local query = "("
        for i, set in ipairs(sets) do
            query = query .. "set:" .. set
            if i < #sets then
                query = query .. "+or+"
            end
        end
        return query .. ")"
    else
        return "set:" .. sets[1]
    end
end

BoosterUrls.makeUrl = function(setQuery, filter)
    return config.apiBaseURL .. setQuery .. "+" .. filter
end

BoosterUrls.basePackUrls = function(sets, includeBasics, extraCommons)
    local urls = {}
    local setQuery = BoosterUrls.makeSetQuery(sets)

    if includeBasics then
        table.insert(urls, BoosterUrls.makeUrl(setQuery, "t:basic+unique:prints"))
    else
        table.insert(urls, BoosterUrls.makeUrl(setQuery, "r:common+-t:basic"))
    end

    for c in ("wubrg"):gmatch(".") do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, "r:common+-t:basic+c>=" .. c))
    end

    extraCommons = extraCommons or 5
    for i = 1, extraCommons do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, "r:common+-t:basic"))
    end

    return urls
end

BoosterUrls.alphaCardPack = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = BoosterUrls.basePackUrls(sets, true, 10)

    for i = 1, 3 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:u'))
    end

    table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:r'))

    BoosterUrls.chooseMasterpieceReplacement(sets, urls)
    return urls
end

BoosterUrls.default14CardPack = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = BoosterUrls.basePackUrls(sets, true, 1)

    for i = 1, 3 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:u'))
    end

    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8000, 300, 36)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(800, 30, 3)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(80, 3, 1)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))

    BoosterUrls.chooseMasterpieceReplacement(sets, urls)
    return urls
end

BoosterUrls.default15CardPack = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = BoosterUrls.basePackUrls(sets, true, 5)

    for i = 1, 3 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:u'))
    end

    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))

    BoosterUrls.chooseMasterpieceReplacement(sets, urls)
    return urls
end

BoosterUrls.default16CardPack = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = BoosterUrls.basePackUrls(sets, true, 3)

    for i = 1, 3 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:u'))
    end

    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(800, 30, 3)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(80, 3, 1)))

    for i = 1, 2 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))
    end

    BoosterUrls.chooseMasterpieceReplacement(sets, urls)
    return urls
end

BoosterUrls.default20CardPack = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = BoosterUrls.basePackUrls(sets, false, 5)

    for i = 1, 5 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, 'r:u'))
    end

    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(800, 30, 3)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(80, 3, 1)))

    for i = 1, 2 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))
    end

    BoosterUrls.chooseMasterpieceReplacement(sets, urls)
    return urls
end

BoosterUrls.beyondBooster = function(sets)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    local urls = {}

    table.insert(urls, BoosterUrls.makeUrl(setQuery, "t:basic"))
    for i = 1, 3 do
        table.insert(urls, BoosterUrls.makeUrl(setQuery, "r:u+-is:boosterfun"))
    end
    table.insert(urls, BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity(8, 1)))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, "r>=u+is:foil"))
    table.insert(urls, BoosterUrls.makeUrl(setQuery, "r>=u+is:boosterfun"))

    return urls
end

BoosterUrls.addCardTypeToPack = function(pack, cardType)
    local randomIndex = math.random(#pack - 1, #pack)
    for i = 13, #pack do
        if randomIndex == i then
            pack[i] = pack[i] .. '+' .. cardType
        else
            pack[i] = pack[i] .. '+-(' .. cardType .. ')'
        end
    end
    return pack
end

BoosterUrls.createReplacementSlotPack = function(urls, sets, removeQuery, addQuery, slotIndex)
    local setQuery = BoosterUrls.makeSetQuery(sets)
    slotIndex = slotIndex or 1
    for i, v in pairs(urls) do
        if i ~= 7 then
            urls[i] = v .. removeQuery
        else
            urls[i] = BoosterUrls.makeUrl(setQuery, BoosterUrls.randomRarity() .. addQuery)
        end
    end
    return urls
end

BoosterUrls.swapLandForCommon = function(urls)
    urls[1] = urls[7]
    return urls
end

BoosterUrls.reverseTable = function(t)
    local rev = {}
    for i = #t, 1, -1 do
        table.insert(rev, t[i])
    end
    return rev
end

BoosterUrls.getSetUrls = function(setCode)
    local entry = setDefinitions[setCode]
    if entry and entry.getUrls ~= null then
        return BoosterUrls.reverseTable(entry.getUrls(setCode))
    end
    return BoosterUrls.reverseTable(BoosterUrls.default15CardPack(setCode))
end

return BoosterUrls

end)
__bundle_register("pack_lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local packLua = [[
-- Any MTG Booster Generator by CoRNeRNoTe
-- Most recent script can be found on GitHub:
-- https://github.com/cornernote/tabletop_simulator-mtg_booster_generator/blob/main/lua/booster-generator.lua
local defaultSetCode = "???"
local defaultPack = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/packs/---_pack.png"
function tryObjectEnter()
    return false
end
function onObjectLeaveContainer(container)
    if container ~= self then
        return
    end
    Wait.condition(function()
        Wait.time(function()
            if container then
                container.destruct()
            end
        end, 1)
    end, function()
        return container and container.getQuantity() == 0
    end)
end
function onLoad()
    local setCode = string.upper(self.getDescription()):match("SET:%s*(%S+)") or self.getName():match("^(.-)%s+Booster$")
    if self.getCustomObject().diffuse == defaultPack then
        self.createButton({
            label = setCode and (setCode .. " Booster") or self.getName(),
            click_function = 'noop',
            function_owner = self,
            position = { 0, 0.2, -1.6 },
            rotation = { 0, 0, 0 },
            width = 1000,
            height = 200,
            font_size = 150,
            color = { 0, 0, 0, 95 },
            hover_color = { 0, 0, 0, 95 },
            press_color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 },
        })
    end
    if setCode ~= defaultSetCode and #self.getObjects() > 0 then
        self.createButton({
            label = "Unpack",
            click_function = "unpackDeck",
            function_owner = self,
            position = { 0, 0.2, 0 },
            rotation = { 0, 0, 0 },
            width = 600,
            height = 200,
            font_size = 150,
            color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 },
        })
    end
end
function unpackDeck()
    local contained = self.getObjects()
    if #contained == 0 then
        return
    end
    local entryGuid = contained[1].guid
    local takePos = self.getPosition() + Vector(0, 6, 0)
    local deck = self.takeObject({ guid = entryGuid, position = takePos, smooth = true })
    if not deck then
        return
    end
    deck.setLock(true)
    deck.setScale({ 2, 1, 2 })
    Wait.time(function()
        spreadDeck(deck)
    end, 0.1)
end
function spreadDeck(deck)
    if not deck then
        return
    end
    local startPos = self.getPosition() + Vector(-2.3 * 2, 2, 3.2)
    local colCount = 5
    local spacingX = 2.3
    local spacingZ = 3.2
    local entries = {}
    if deck.tag == "Deck" then
        entries = deck.getObjects()
    else
        entries = { {} }
    end
    for index, entry in ipairs(entries) do
        Wait.time(function()
            local row = math.floor((index - 1) / colCount)
            local col = (index - 1) % colCount
            local pos = startPos + Vector(col * spacingX, 2, -row * spacingZ)
            if deck.tag == "Deck" then
                local takeParams = { position = pos, smooth = true }
                if entry.guid then
                    takeParams.guid = entry.guid
                end
                local card = deck.takeObject(takeParams)
                if card then
                    Wait.time(function()
                        if card ~= null then
                            card.setScale({ 1, 1, 1 })
                        end
                    end, 0.05)
                end
                if deck.remainder then
                    deck = deck.remainder
                    deck.setLock(true)
                end
            else
                deck.setScale({ 1, 1, 1 })
                deck.setLock(false)
                deck.setPositionSmooth(pos, false, false)
            end
        end, index * 0.8)
    end
    self.destruct()
end
function noop()
end
]]

return packLua

end)
__bundle_register("state", function(require, _LOADED, __bundle_register, __bundle_modules)
local data = {
    setCode = "???",
    boosterCount = 0,
    timePassed = 0,
    requestStartupDelay = 0,
    rateLimitCooldown = 0,
    rateLimitObject = nil,
    lastDescription = "",
    requestQueue = {},
    setCaches = {},
    setCacheLoads = {},
    queryCaches = {},
    emptyQueryCaches = {},
    queryCacheLoads = {},
    cacheJobs = {},
    reloadToken = 0,
}

return data

end)
__bundle_register("config", function(require, _LOADED, __bundle_register, __bundle_modules)
local config = {
    backURL = 'https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/',
    apiBaseURL = 'https://api.scryfall.com/cards/random?q=',
    searchBaseURL = 'https://api.scryfall.com/cards/search?order=set&unique=prints&q=',
    defaultPackImage = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/packs/---_pack.png", -- same url used in packLua
    defaultSetCode = "???", -- same setCode used in packLua
    pollInterval = 1.2,
    rateLimitDelay = 60,
    requestStartupJitter = 3,
    imageLoadDelay = 0.1,
    imageProxyBaseURL = "https://images.weserv.nl/?url=",
    cacheChunkSize = 25,
}

return config

end)
__bundle_register("auto_updater", function(require, _LOADED, __bundle_register, __bundle_modules)
local AutoUpdater = {
    name = "Any MTG Booster Generator",
    version = "1.7.27",
    versionUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/refs/heads/main/lua/booster-generator.ver",
    scriptUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/refs/heads/main/lua/booster-generator.lua",
    debug = false,

    run = function(self, host)
        self.host = host
        if not self.host then
            self:error("Error: host not set, ensure AutoUpdater:run(self) is in your onLoad() function")
            return
        end
        self:checkForUpdate()
    end,
    checkForUpdate = function(self)
        WebRequest.get(self.versionUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to check version (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            local remoteVersion = request.text:match("[^\r\n]+") or ""
            if self:isNewerVersion(remoteVersion) then
                self:fetchNewScript(remoteVersion)
            end
        end)
    end,
    isNewerVersion = function(self, remoteVersion)
        local function split(v)
            return { v:match("^(%d+)%.?(%d*)%.?(%d*)") or 0 }
        end
        local r, l = split(remoteVersion), split(self.version)
        for i = 1, math.max(#r, #l) do
            local rv, lv = tonumber(r[i]) or 0, tonumber(l[i]) or 0
            if rv ~= lv then
                return rv > lv
            end
        end
        return false
    end,
    fetchNewScript = function(self, newVersion)
        WebRequest.get(self.scriptUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to fetch new script (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            if request.text and #request.text > 0 then
                self.host.setLuaScript(request.text)
                self:print("Updated to version " .. newVersion)
                Wait.condition(function()
                    return not self.host or self.host.reload()
                end, function()
                    return not self.host or self.host.resting
                end)
            else
                self:error("New script is empty")
            end
        end)
    end,
    print = function(self, message)
        print(self.name .. ": " .. message)
    end,
    error = function(self, message)
        if self.debug then
            error(self.name .. ": " .. message)
        end
    end,
}

return AutoUpdater

end)
return __bundle_require("__root")
