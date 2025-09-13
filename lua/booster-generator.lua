-- Any MTG Booster Generator by CoRNeRNoTe
-- Generate any (well, many) boosters.

-- Most recent script can be found on GitHub:
-- https://github.com/cornernote/tabletop_simulator-mtg_booster_generator/blob/main/lua/booster-generator.lua

local config = {
    backURL = 'https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/',
    apiBaseURL = 'http://api.scryfall.com/cards/random?q='
}

local packLua = [[
-- Any MTG Booster Generator by CoRNeRNoTe
-- Most recent script can be found on GitHub:
-- https://github.com/cornernote/tabletop_simulator-mtg_booster_generator/blob/main/lua/booster-generator.lua
function tryObjectEnter()
    return false
end
function onObjectLeaveContainer(container)
    if container ~= self then
        return
    end
    Wait.time(function()
        Wait.condition(
                function()
                    if container ~= nil then
                        container.destruct()
                    end
                end,
                function()
                    return container ~= nil and container.getQuantity() == 0
                end
        )
    end, 1)
end
]]

local packLabelLua = [[
function onLoad()
    self.createButton({
        label = self.getName() or "",
        click_function = 'null',
        function_owner = self,
        position = { 0, 0.2, -1.6 },
        rotation = { 0, 0, 0 },
        width = 1000,
        height = 200,
        font_size = 150,
        color = { 0, 0, 0, 95 },
        font_color = { 1, 1, 1, 95 },
    })
end
]]

local boosterCount = 0
local boosterDataCache = {}
local cardStackDescription = ""
local lastDescription = ""
local pollInterval = 0.15  -- seconds, limit scryfall API requests to <10/sec
local timePassed = 0
local requestQueue = {}

local default = {
    pack = "https://steamusercontent-a.akamaihd.net/ugc/12555777445170015064/1F22F21DA19B1C5D668D761C2CA447889AE98A2A/",
    name = "???",
}

local setImages = {
    mystery = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1871804141033719694/FE0CC0C11B5ADB27831BAAF0FF37E95852B6F454/",
        name = "Mystery",
    },
    fin = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/16627771293824374075/C5699273F56C725E5F909A4CF68E0BBB40CB3212/",
        name = "Final Fantasy",
    },
    inr = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33314777894966905/8D9807FCC410A72E23B650DD45417ADE665B4E87/",
        name = "Innistrad Remaster",
    },
    dft = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33315411545885589/0C728D0BDFAB373310773FA4546CC4E08B1B11A1/",
        name = "Aetherdrift",
    },
    eoe = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/15223391781034002798/18D4F50FA52D5739A7AAF47270CD89A8F3161F20/",
        name = "Edge of Eternities",
    },
    tdm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33320655968555543/9ADDB19799EBAE44174466FE19E0C52F73EDDAE4/",
        name = "",
    },
    fdn = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666062860/0DFCD530284A8A4EC67CCEA18399BDE9405F3C3C/",
        name = "Foundations",
    },
    dsk = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666215369/BFD6BBAC0DE7F1F5C810F4FFCA8EF5E50EC8A03E/",
        name = "Duskmourn: House of Horror",
    },
    blb = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666242938/FA118E357C5820C6BF4EC70CAECC88876B22DE41/",
        name = "Bloomburrow",
    },
    mh3 = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666331598/112B58990D8AD19B704448588F6CC34A8BF0E2E9/",
        name = "Modern Horizons III",
    },
    mkm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666403145/D578E8D070D0F89BB866212A8C5FD97AE840F418/",
        name = "Murders at Karlov Manor",
    },
    otj = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666361741/B40E45A8AE490D38D02C8D32295E71920362D781/",
        name = "Outlaws of Thunder Junction",
    },
    rvr = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/33313055666416970/8B9F38A1D618C5C025C45E8D484B097CA8F245EE/",
        name = "Ravnica Remastered"
    },
    xln = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/861734852198387392/B81155A30E28760116D166987C221F946D37380E/",
        name = "Ixalan",
    },
    khm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1734441450301159293/A7F7C010D0312D856CD8667678F5732BDB8F6EB2/",
        name = "Kaldheim",
    },
    mid = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1734441450308868762/12F6CE09A39E5FEC3B472EBE54562B92A7332027/",
        name = "Innistrad: Midnight Hunt",
    },
    stx = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1734441184603578733/2009A7D782D40F1456733EFE30ACC064D12B5FFD/",
        name = "StrixHaven",
    },
    afr = {
        name = "Adventures in the Forgotten Realms",
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1734441262522564318/D44434D1C56BA4A590591606A3A50EE4C9F607B8/",
    },
    ust = {
        pack = {
            "https://steamusercontent-a.akamaihd.net/ugc/1869553886384090159/B009BD275EAA4E4D327CABF6E9C287FCF974CAE0/",
            "https://steamusercontent-a.akamaihd.net/ugc/1869553886384088312/840D789FDE909D82F2943ADC26138DD838C6D3CD/",
            "https://steamusercontent-a.akamaihd.net/ugc/1869553610271665770/97276A7B7774EF057E915B9A0AB9AC3F81221ED2/",
        },
        name = "Unstable",
    },
    ugl = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1869553610271718076/9F874EFF82054749352677189F63683DC038A17E/",
        name = "Unglued",
    },
    unh = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/1869553610271611558/564F7D6B23A479883C84C4F5D90852CD4C056E9A/",
        name = "Unhinged",
    },
    vow = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/2027238089146067515/FB7A98B9B0BE5C25098F63981C6C12BBE1036BA6/",
        name = "Inistrad Crimson VOW",
    },
    uma = {
        pack = "https://i.imgur.com/4RylXgU.png",
        name = "Ultimate Masters",
    },
    cmm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/2093668098031059945/BF91A05DA4A788ED5F5C01B05305F3E4ECE8CE52/",
        name = "Commander Masters",
    },
    mma = {
        pack = "https://i.imgur.com/CU7EL6h.png",
        name = "Modern Masters",
    },
    twoxm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/2027238089151521799/52EC298FBB89EA2A24DA024981161F96E3522645/",
        name = "Double Masters",
        code = "2XM"
    },
    sok = {
        pack = "https://i.imgur.com/ctFTHkw.jpg",
        name = "Saviors of Kamigawa",
    },
    neo = {
        pack = "https://i.imgur.com/5FcGpqC.png",
        name = "Kamigawa: Neon Dynasty",
    },
    bok = {
        pack = "https://i.imgur.com/t6UP7lt.jpg",
        name = "Betrayers of Kamigawa",
    },
    chk = {
        pack = "https://i.imgur.com/E7IW8Tv.jpg",
        name = "Champions of Kamigawa",
    },
    spm = {
        pack = "https://steamusercontent-a.akamaihd.net/ugc/11967831829609287872/6D168435BEFB1C1EE50A4F0B286BF4D8D9FEA7C8/",
        name = "Marvel's Spider-Man",
    },
}

local setCodeMapping = {
    ['2xm'] = 'twoxm',
    ['???'] = 'empty',
}

function onObjectLeaveContainer(container, leaveObject)
    if container ~= self then
        return
    end

    local setCode = getSetCode()

    leaveObject.setName(setCode .. " Booster")
    boosterCount = boosterCount + 1
    local currentBoosterID = boosterCount

    local urls = getSetUrls(setCode)
    fetchDeckData(currentBoosterID, urls, leaveObject)

    leaveObject.createButton({
        label = "generating " .. setCode,
        click_function = 'null',
        function_owner = self,
        position = { 0, 0.2, -1.6 },
        rotation = { 0, 0, 0 },
        width = 1000,
        height = 200,
        font_size = 100,
        color = { 0, 0, 0, 95 },
        font_color = { 1, 1, 1, 95 },
    })

    local packImage = getPackImage(setCode)

    leaveObject.setCustomObject({
        diffuse = packImage
    })

    Wait.condition(
            function()
                Wait.condition(
                        function()
                            local objectData = leaveObject.getData()
                            objectData.ContainedObjects = boosterDataCache[currentBoosterID]
                            leaveObject.destruct()
                            local generatedBooster = spawnObjectData({ data = objectData })
                            local packLuaScript = packLua
                            if packImage == default.pack then
                                packLuaScript = packLuaScript .. "\n" .. packLabelLua
                            end
                            generatedBooster.setLuaScript(packLuaScript)
                        end,
                        function()
                            return leaveObject.resting
                        end
                )
            end,
            function()
                return boosterDataCache[currentBoosterID] ~= nil
            end
    )
end

function getPackImage(setCode)
    local mappedSetCode = setCodeMapping[string.lower(setCode)] or string.lower(setCode)
    local packImage = setImages[mappedSetCode] and setImages[mappedSetCode].pack

    if packImage then
        if type(packImage) == "string" then
            return packImage
        elseif type(packImage) == "table" then
            return packImage[math.random(1, #packImage)]
        end
    end

    return default.pack
end

function drawBox()
    self.clearButtons()

    local setCode = getSetCode()
    local packImage = getPackImage(setCode)

    if self.getCustomObject().diffuse ~= packImage then
        self.setCustomObject({
            diffuse = packImage
        })
        self.reload()
    end

    if packImage == default.pack then
        self.createButton({
            label = setCode .. " Boosters",
            click_function = 'null',
            function_owner = self,
            position = { 0, 0.2, -1.6 },
            rotation = { 0, 0, 0 },
            width = 1000,
            height = 200,
            font_size = 150,
            color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 },
        })

        if #setCode > 3 then
            self.editButton({ index = 0, font_size = 150 })
        end
    end
end

function onLoad()
    drawBox()
    lastDescription = self.getDescription()
    self.addContextMenuItem("Spawn Boxes", spawnSupportedPacks)
end

function spawnSupportedPacks()
    local sets = {}
    for code, _ in pairs(setImages) do
        table.insert(sets, code)
    end
    table.sort(sets)

    local startPos = self.getPosition() + Vector(3, 0, 0)
    local cols = 10
    local spacingX = 3
    local spacingY = 5

    for index, code in ipairs(sets) do
        local row = math.floor((index - 1) / cols)
        local col = (index - 1) % cols
        local copy = self.clone({
            position = {
                x = startPos.x + col * spacingX,
                y = startPos.y,
                z = startPos.z - row * spacingY
            },
            snap_to_grid = false,
        })
        copy.setDescription("SET: " .. string.upper(code))
    end
end

function onUpdate()
    timePassed = timePassed + Time.delta_time
    if timePassed >= pollInterval then
        timePassed = 0
        checkDescription()
        processRequestQueue()
    end
end

function checkDescription()
    local description = self.getDescription()

    if description ~= lastDescription then
        lastDescription = description
        drawBox()
    end
end

function getSetCode()
    -- Trim leading/trailing whitespace from the captured text
    -- This makes sure " SET: M15 " becomes "M15"
    local setCode = string.upper(self.getDescription()):match("SET:%s*(%S+)") or default.name

    if #setCode > 3 then
        setCode = string.lower(setCode):gsub("^%l", string.upper)
    else
        setCode = string.upper(setCode)
    end

    return setCode
end

local BoosterPacks = {}
local apiSetPrefix = config.apiBaseURL .. 'is:booster+s:'

local function getRandomRarity(mythicChance, rareChance, uncommonChance)
    if math.random(1, mythicChance or 36) == 1 then
        return 'r:mythic'
    elseif math.random(1, rareChance or 8) == 1 then
        return 'r:rare'
    elseif math.random(1, uncommonChance or 4) == 1 then
        return 'r:uncommon'
    else
        return 'r:common'
    end
end

local function addCardTypeToPack(pack, cardType)
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

local MasterpieceSets = {
    bfz = 'exp', ogw = 'exp', kld = 'mps', aer = 'mps',
    akh = 'mp2', hou = 'mp2', stx = 'sta',
    tsp = 'tsb', mb1 = 'fmb1', mh2 = 'h1r'
}

function BoosterPacks.default(set)
    local urls = {}
    local url = apiSetPrefix .. set .. '+'
    url = url:gsub('%+s:%(', '+(')

    table.insert(urls, url .. 't:basic')
    for c in ('wubrg'):gmatch('.') do
        table.insert(urls, url .. 'r:common+c>=' .. c)
    end
    for i = 1, 5 do
        table.insert(urls, url .. 'r:common+')
    end
    for i = 1, 3 do
        table.insert(urls, url .. 'r:uncommon')
    end

    table.insert(urls, url .. getRandomRarity(8, 1))

    if MasterpieceSets[set] and math.random(1, 144) == 1 then
        urls[#urls] = config.apiBaseURL .. 's:' .. MasterpieceSets[set]
    end

    return urls
end

function BoosterPacks.dom(set)
    return addCardTypeToPack(BoosterPacks.default(set), 't:legendary')
end
function BoosterPacks.war(set)
    return addCardTypeToPack(BoosterPacks.default(set), 't:planeswalker')
end
function BoosterPacks.znr(set)
    return addCardTypeToPack(BoosterPacks.default(set), 't:land+(is:spell+or+pathway)')
end

function BoosterPacks.twoxm(set)
    local urls = BoosterPacks.default(set)
    urls[1] = urls[7]
    urls[11] = urls[#urls]
    for i = 9, 10 do
        urls[i] = apiSetPrefix .. '2xm' .. '+' .. getRandomRarity()
    end
    return urls
end

local function createReplacementSlotPack(urls, set, removeQuery, addQuery)
    for i, v in pairs(urls) do
        if i ~= 6 then
            urls[i] = v .. removeQuery
        else
            urls[i] = apiSetPrefix .. set .. '+' .. getRandomRarity() .. addQuery
        end
    end
    return urls
end

for _, s in ipairs({ 'isd', 'dka', 'soi', 'emn' }) do
    BoosterPacks[s] = function(set)
        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-is:transform', '+is:transform')
    end
end

for _, s in ipairs({ 'mid' }) do
    BoosterPacks[s] = function(set)
        local urls = BoosterPacks.default(set)
        local transformIndex = math.random(#urls - 1, #urls)
        for i, v in pairs(urls) do
            if i == 6 or i == transformIndex then
                urls[i] = v .. '+is:transform'
            else
                urls[i] = v .. '+-is:transform'
            end
        end
        return urls
    end
end

for _, s in ipairs({ 'cns', 'cn2' }) do
    BoosterPacks[s] = function(set)
        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-wm:conspiracy', '+wm:conspiracy')
    end
end

--for _, s in ipairs({ 'rav', 'gpt', 'dis', 'rtr', 'gtc', 'dgm', 'grn', 'rna' }) do
--    BoosterPacks[s] = function(set)
--        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-t:land', '+t:land')
--    end
--end

for _, s in ipairs({ 'ice', 'all', 'csp', 'mh1', 'khm' }) do
    BoosterPacks[s] = function(set)
        local urls = BoosterPacks.default(set)
        urls[7] = apiSetPrefix .. set .. '+t:basic+t:snow'
        return urls
    end
end

BoosterPacks.empty = function()
    return {}
end

BoosterPacks.mystery = function()
    local urls = {}
    local urlPrefix = config.apiBaseURL .. 'set:mb1+'
    for _, c in ipairs({ 'w', 'u', 'b', 'r', 'g' }) do
        table.insert(urls, urlPrefix .. 'r<rare+c=' .. c)
        table.insert(urls, urlPrefix .. 'r<rare+c=' .. c)
    end
    table.insert(urls, urlPrefix .. 'c:m+r<rare')
    table.insert(urls, urlPrefix .. 'c:c+r<rare')
    table.insert(urls, urlPrefix .. 'r>=rare+frame:2015')
    table.insert(urls, urlPrefix .. 'r>=rare+-frame:2015')
    table.insert(urls, config.apiBaseURL .. 'set:cmb1')
    return urls
end

BoosterPacks.spm = function()
    local big = 1000000000000;
    local urls = {}
    local url = config.apiBaseURL .. 's:spm+'
    table.insert(urls, url .. 't:basic')
    for i = 1, 6 do
        table.insert(urls, url .. 'r:common')
    end
    for i = 1, 3 do
        table.insert(urls, url .. 'r:uncommon')
    end
    table.insert(urls, url .. getRandomRarity(big, 1))
    table.insert(urls, url .. getRandomRarity(8, 3, 1))
    table.insert(urls, url .. getRandomRarity(big, 30, 3))
    table.insert(urls, url .. getRandomRarity(big, 300, big))
    return urls
end

BoosterPacks.stx = function()
    local urls = {}
    local url = apiSetPrefix .. 'stx+'
    local archiveURL = config.apiBaseURL .. 'set:sta+r>common+'
    table.insert(urls, archiveURL .. (math.random(2) == 1 and 'lang:en' or 'lang:ja'))
    table.insert(urls, url .. 't:lesson+-r:u')
    table.insert(urls, url .. getRandomRarity(8, 1))
    for i = 1, 3 do
        table.insert(urls, url .. 'r:u')
    end
    for _, c in ipairs({ 'w', 'u', 'b', 'r', 'g' }) do
        table.insert(urls, url .. 'r:c+c:' .. c)
    end
    for i = 1, 3 do
        table.insert(urls, url .. 'r:c')
    end

    if math.random(3) == 1 then
        table.insert(urls, url)
    else
        table.insert(urls, url .. 'r:c')
    end
    return urls
end

local function createCustomBooster(setQuery, packStructure)
    return function()
        local urls = BoosterPacks.default(setQuery)
        return packStructure(urls)
    end
end

BoosterPacks.standard = createCustomBooster('f:standard', function(urls)
    local url = config.apiBaseURL .. 'f:standard+'
    local artSets = '(set:tafr+or+set:tstx+or+set:tkhm+or+set:tznr+or+set:sznr+or+set:tm21+or+set:tiko+or+set:tthb+or+set:teld)'
    local artQuery = '(border:borderless+or+frame:showcase+or+frame:extendedart+or+set:plist+or+set:sta)'
    table.insert(urls, url .. 't:basic')
    table.insert(urls, config.apiBaseURL .. artSets)
    if math.random(2) == 1 then
        urls[#urls - 1] = url .. artQuery
    end
    if math.random(2) == 1 then
        urls[#urls] = url .. artQuery
    end
    return urls
end)

BoosterPacks.conspiracy = createCustomBooster('(s:cns+or+s:cn2)', function(urls)
    table.insert(urls, urls[#urls]:gsub('r:%S+', getRandomRarity(9, 6, 3)))
    urls[6] = urls[math.random(11, 12)]
    for i, _ in pairs(urls) do
        local query = (i == 6 or i == #urls) and '+wm:conspiracy' or '+-wm:conspiracy'
        urls[i] = urls[i] .. query
    end
    return urls
end)

BoosterPacks.innistrad = createCustomBooster('(s:isd+or+s:dka+or+s:avr+or+s:soi+or+s:emn+or+s:mid)', function(urls)
    table.insert(urls, urls[#urls]:gsub('r:%S+', getRandomRarity(8, 1)))
    urls[11] = urls[12]
    for i, _ in pairs(urls) do
        local query = (i == 6 or i == #urls or i == #urls - 2) and '+is:transform' or '+-is:transform'
        urls[i] = urls[i] .. query
    end
    return urls
end)

BoosterPacks.ravnica = createCustomBooster('(s:rav+or+s:gpt+or+s:dis+or+s:rtr+or+s:gtc+or+s:dgm+or+s:grn+or+s:rna)', function(urls)
    local landQuery = 't:land'
    table.insert(urls, urls[#urls])
    for i = 7, 9 do
        urls[i] = urls[6] .. '+id>=2'
    end
    for i, _ in pairs(urls) do
        if i == 6 or i == #urls then
            urls[i] = urls[i]:gsub('r:%S+', getRandomRarity(9, 6, 3)) .. '+' .. landQuery
        else
            urls[i] = urls[i] .. '+-' .. landQuery
        end
    end
    return urls
end)

function enqueueRequest(url, callback)
    table.insert(requestQueue, { url = url, callback = callback })
end

function processRequestQueue()
    if #requestQueue == 0 then
        return
    end
    local req = table.remove(requestQueue, 1)
    WebRequest.get(req.url, req.callback)
end

function getSetUrls(setCode)
    local lowerSetCode =  string.lower(setCode)
    local mappedSetCode = setCodeMapping[lowerSetCode] or lowerSetCode
    local packGenerator = BoosterPacks[mappedSetCode] or BoosterPacks.default
    return reverseTable(packGenerator(lowerSetCode))
end

function reverseTable(t)
    local rev = {}
    for i = #t, 1, -1 do
        table.insert(rev, t[i])
    end
    return rev
end

function fetchDeckData(boosterID, urls, leaveObject, attempts, existingDeck, replaceIndices, originalUrls)
    attempts = attempts or 0
    originalUrls = originalUrls or urls

    local setCode = getSetCode()

    local deck = existingDeck or {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 180, rotZ = 180, scaleX = 1, scaleY = 1, scaleZ = 1 },
        Name = "Deck",
        Nickname = setCode .. " Booster",
        Description = cardStackDescription,
        DeckIDs = {},
        CustomDeck = {},
        ContainedObjects = {},
    }

    local requestsPending = #urls
    local requestsCompleted = 0
    local requestErrors = {}

    for j, url in ipairs(urls) do
        local i = replaceIndices and replaceIndices[j] or j
        enqueueRequest(url, function(request)
            if request.response_code == 200 then
                local cardData = createCardDataFromJSON(request.text, i)
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

            local remaining = requestsPending - requestsCompleted
            local label = "Generating " .. setCode .. " (" .. (remaining + 1) .. ")"
            if attempts > 0 then
                label = "Deduping " .. setCode .. " (" .. (attempts + 1) .. ": " .. (remaining + 1) .. ")"
            end
            if leaveObject then
                leaveObject.editButton({
                    index = 0,
                    label = label,
                })
            end
        end)
    end

    Wait.condition(
            function()
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
                        fetchDeckData(boosterID, dupeUrls, leaveObject, attempts + 1, deck, dupes, originalUrls)
                    end, 0.1)
                else
                    local boosterContents = {}
                    if setCode == default.name then
                        table.insert(boosterContents, {
                            Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
                            Name = "Notecard",
                            Nickname = 'REPLACE "SET: XXX" IN BOX DESCRIPTION',
                            Description = "\nAlmost all sets are supported, see:\nhttps://scryfall.com/sets\n\nCustom pack images are available for:\n" .. getSupportedSets(),
                            Grid = false,
                            Snap = false,
                        })
                    else
                        table.insert(boosterContents, deck)
                    end

                    for _, error in ipairs(requestErrors) do
                        table.insert(boosterContents, {
                            Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
                            Name = "Notecard",
                            Nickname = "Booster Generation Error",
                            Description = "url: " .. error.url .. "\n\n" .. error.message,
                            Grid = false,
                            Snap = false,
                        })
                    end

                    boosterDataCache[boosterID] = boosterContents
                end
            end,
            function()
                return requestsPending == requestsCompleted
            end
    )
end

function getCardOracleText(cardFace)
    local powerToughness = ""
    if cardFace.power then
        powerToughness = '\n[b]' .. cardFace.power .. '/' .. cardFace.toughness .. '[b]'
    elseif cardFace.loyalty then
        powerToughness = '\n[b]' .. tostring(cardFace.loyalty) .. '[/b]'
    end
    return (cardFace.oracle_text or "") .. powerToughness
end

function createCardDataFromJSON(jsonString, cardIndex)
    local card = JSON.decode(jsonString)
    if not card or not card.name then
        error("Failed to decode JSON: " .. jsonString)
        return
    end

    local cardName = ""
    local cardOracle = ""
    local faceURL = ""
    local backData = nil
    local imageQuality = 'large'
    local cacheBuster = (card.image_status ~= 'highres_scan') and ('?' .. os.date("%Y%m%d")) or ""

    local function getFormattedName(face, typeSuffix)
        return string.format('%s\n%s %s CMC %s', face.name:gsub('"', ''), face.type_line, tostring(card.cmc or face.cmc or 0), typeSuffix or ""):gsub('%s$', '')
    end

    if card.card_faces then
        if card.image_uris then
            cardName = getFormattedName(card.card_faces[1])
            for i, face in ipairs(card.card_faces) do
                cardOracle = cardOracle .. getFormattedName(face) .. '\n' .. getCardOracleText(face)
                if i < #card.card_faces then
                    cardOracle = cardOracle .. '\n'
                end
            end
            faceURL = card.image_uris.normal:gsub('%?.*', ''):gsub('normal', imageQuality) .. cacheBuster
        else
            local face = card.card_faces[1]
            local back = card.card_faces[2]
            cardName = getFormattedName(face, 'DFC')
            cardOracle = getCardOracleText(face)
            faceURL = face.image_uris.normal:gsub('%?.*', ''):gsub('normal', imageQuality) .. cacheBuster
            local backURL = back.image_uris.normal:gsub('%?.*', ''):gsub('normal', imageQuality) .. cacheBuster
            local backCardIndex = cardIndex + 100
            backData = {
                Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 0, rotZ = 0, scaleX = 1, scaleY = 1, scaleZ = 1 },
                Name = "Card",
                Nickname = getFormattedName(back, 'DFC'),
                Description = getCardOracleText(back),
                Memo = card.oracle_id,
                CardID = backCardIndex * 100,
                CustomDeck = {
                    [backCardIndex] = {
                        FaceURL = backURL, BackURL = config.backURL, NumWidth = 1, NumHeight = 1,
                        Type = 0, BackIsHidden = true, UniqueBack = false
                    }
                },
            }
        end
    else
        cardName = getFormattedName(card)
        cardOracle = getCardOracleText(card)
        faceURL = card.image_uris.normal:gsub('%?.*', ''):gsub('normal', imageQuality) .. cacheBuster
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
        },
    }

    if backData then
        cardData.States = { [2] = backData }
    end

    return cardData
end

function getSupportedSets()
    local packs = {}

    for code, data in pairs(setImages) do
        if data.pack then
            table.insert(packs, data.code or string.upper(code))
        end
    end

    return table.concat(packs, ", ")
end