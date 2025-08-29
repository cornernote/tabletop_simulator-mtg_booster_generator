--- Global Configuration ---
local config = {
    backURL = 'https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/',
    apiBaseURL = 'http://api.scryfall.com/cards/random?q='
}

--- Script State ---
local boosterCount = 0
local boosterDataCache = {}
local cardStackDescription = ""
local lastDescription = ""
local pollInterval = 1.0  -- seconds
local timePassed = 0

--- Function Hooks ---
function onObjectLeaveContainer(container, leave_object)
    if container ~= self then
        return
    end

    local setCode = getSetCode()

    leave_object.setName(setCode .. " Booster")
    boosterCount = boosterCount + 1
    local currentBoosterID = boosterCount

    local queryTable = getScryfallQueryTable()
    fetchDeckData(queryTable, currentBoosterID)

    leave_object.createButton(makeBoosterLabelParams("generating " .. setCode))

    Wait.condition(
            function()
                Wait.condition(
                        function()
                            local objectData = leave_object.getData()
                            objectData.ContainedObjects = { boosterDataCache[currentBoosterID] }
                            leave_object.destruct()
                            local generatedBooster = spawnObjectData({ data = objectData })

                            generatedBooster.createButton(makeBoosterLabelParams(setCode .. " Booster"))
                        end,
                        function()
                            return leave_object.resting
                        end
                )
            end,
            function()
                return boosterDataCache[currentBoosterID] ~= nil
            end
    )
end

function onLoad()
    local setCode = getSetCode()
    self.createButton({
        click_function = "null",
        function_owner = self,
        label = setCode .. " Boosters",
        position = { 0.025, -0.22, 0.355 },
        rotation = { 270, 0, 0 },
        color = { 0.1, 0.1, 0.1, 1 },
        font_color = { 0.8, 0.8, 0.8, 0.8 },
        scale = { 0.25, 0.25, 0.7 },
        width = 0,
        height = 0,
        font_size = 220,
    })

    self.createButton({
        click_function = "null",
        function_owner = self,
        label = setCode,
        position = { 0.025, 0.5, -0.5 },
        rotation = { 270, 0, 0 },
        color = { 0.1, 0.1, 0.1, 1 },
        font_color = { 0.8, 0.8, 0.8, 0.8 },
        scale = { 0.25, 0.25, 0.7 },
        width = 0,
        height = 0,
        font_size = 500,
    })
end

function onUpdate()
    timePassed = timePassed + Time.delta_time
    if timePassed >= pollInterval then
        timePassed = 0
        checkDescription()
    end
end

function checkDescription()
    local description = self.getDescription()
    if description ~= lastDescription then
        lastDescription = description
        self.editButton({ index = 0, label = getSetCode() .. " Boosters" })
    end
end

--- Booster Generation Logic ---
function makeBoosterLabelParams(label)
    return {
        label = label,
        click_function = 'null',
        function_owner = self,
        position = { 0, 0.2, -1.6 },
        rotation = { 0, 0, 0 },
        width = 0,
        height = 0,
        font_size = 100,
        color = { 0, 0, 0, 0 },
        font_color = { 1, 1, 1, 100 },
    }
end

function getSetCode()
    local captured_text = self.getDescription():match("SET:%s*([^\n]+)")

    if captured_text then
        -- Trim leading/trailing whitespace from the captured text
        -- This makes sure " SET: M15 " becomes "M15"
        return captured_text:match("^%s*(.-)%s*$")
    end

    return "mystery"
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
    local pack = {}
    local url = apiSetPrefix .. set .. '+'
    url = url:gsub('%+s:%(', '+(')

    for c in ('wubrg'):gmatch('.') do
        table.insert(pack, url .. 'r:common+c>=' .. c)
    end
    for i = 1, 6 do
        table.insert(pack, url .. 'r:common+-t:basic')
    end
    for i = 1, 3 do
        table.insert(pack, url .. 'r:uncommon')
    end

    table.insert(pack, url .. getRandomRarity(8, 1))

    if MasterpieceSets[set] and math.random(1, 144) == 1 then
        pack[#pack] = config.apiBaseURL .. 's:' .. MasterpieceSets[set]
    end

    return pack
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

-- Changed function name to be a valid Lua identifier for clarity.
function BoosterPacks.twoxm(set)
    local pack = BoosterPacks.default(set)
    pack[11] = pack[#pack]
    for i = 9, 10 do
        pack[i] = apiSetPrefix .. '2xm' .. '+' .. getRandomRarity()
    end
    return pack
end

local function createReplacementSlotPack(pack, set, removeQuery, addQuery)
    for i, v in pairs(pack) do
        if i ~= 6 then
            pack[i] = v .. removeQuery
        else
            pack[i] = apiSetPrefix .. set .. '+' .. getRandomRarity() .. addQuery
        end
    end
    return pack
end

for _, s in ipairs({ 'isd', 'dka', 'soi', 'emn' }) do
    BoosterPacks[s] = function(set)
        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-is:transform', '+is:transform')
    end
end

for _, s in ipairs({ 'mid' }) do
    BoosterPacks[s] = function(set)
        local pack = BoosterPacks.default(set)
        local transformIndex = math.random(#pack - 1, #pack)
        for i, v in pairs(pack) do
            if i == 6 or i == transformIndex then
                pack[i] = v .. '+is:transform'
            else
                pack[i] = v .. '+-is:transform'
            end
        end
        return pack
    end
end

for _, s in ipairs({ 'cns', 'cn2' }) do
    BoosterPacks[s] = function(set)
        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-wm:conspiracy', '+wm:conspiracy')
    end
end

for _, s in ipairs({ 'rav', 'gpt', 'dis', 'rtr', 'gtc', 'dgm', 'grn', 'rna' }) do
    BoosterPacks[s] = function(set)
        return createReplacementSlotPack(BoosterPacks.default(set), set, '+-t:land', '+t:land+-t:basic')
    end
end

for _, s in ipairs({ 'ice', 'all', 'csp', 'mh1', 'khm' }) do
    BoosterPacks[s] = function(set)
        local pack = BoosterPacks.default(set)
        pack[6] = apiSetPrefix .. set .. '+t:basic+t:snow'
        return pack
    end
end

BoosterPacks.mystery = function()
    local urlTable = {}
    local urlPrefix = config.apiBaseURL .. 'set:mb1+'
    for _, c in ipairs({ 'w', 'u', 'b', 'r', 'g' }) do
        table.insert(urlTable, urlPrefix .. 'r<rare+c=' .. c)
        table.insert(urlTable, urlPrefix .. 'r<rare+c=' .. c)
    end
    table.insert(urlTable, urlPrefix .. 'c:m+r<rare')
    table.insert(urlTable, urlPrefix .. 'c:c+r<rare')
    table.insert(urlTable, urlPrefix .. 'r>=rare+frame:2015')
    table.insert(urlTable, urlPrefix .. 'r>=rare+-frame:2015')
    table.insert(urlTable, config.apiBaseURL .. 'set:cmb1')
    return urlTable
end

BoosterPacks.spm = function()
    local urlTable = {}
    local urlPrefix = config.apiBaseURL .. 's:spm+'

    for i = 1, math.random(6, 9) do
        table.insert(urlTable, urlPrefix .. 'r:common')
    end
    for i = 1, math.random(3, 5) do
        table.insert(urlTable, urlPrefix .. 'r:uncommon')
    end
    table.insert(urlTable, urlPrefix .. 't:land')

    local numRares = 1
    local rareRoll = math.random(1, 200)
    if rareRoll == 1 then
        numRares = 4
    elseif rareRoll <= 7 then
        numRares = 3
    elseif rareRoll <= 70 then
        numRares = 2
    end
    for i = 1, numRares do
        table.insert(urlTable, urlPrefix .. getRandomRarity(8, 1))
    end

    table.insert(urlTable, urlPrefix .. getRandomRarity(nil, nil, 4))
    return urlTable
end

BoosterPacks.stx = function()
    local pack = {}
    local url = apiSetPrefix .. 'stx+'
    local archiveURL = config.apiBaseURL .. 'set:sta+r>common+'
    table.insert(pack, archiveURL .. (math.random(2) == 1 and 'lang:en' or 'lang:ja'))
    table.insert(pack, url .. 't:lesson+-r:u')
    table.insert(pack, url .. getRandomRarity(8, 1))
    for i = 1, 3 do
        table.insert(pack, url .. 'r:u')
    end
    for _, c in ipairs({ 'w', 'u', 'b', 'r', 'g' }) do
        table.insert(pack, url .. 'r:c+c:' .. c)
    end
    for i = 1, 3 do
        table.insert(pack, url .. 'r:c+-t:basic')
    end

    if math.random(3) == 1 then
        table.insert(pack, url)
    else
        table.insert(pack, url .. 'r:c+-t:basic')
    end
    return pack
end

local function createCustomBooster(setQuery, packStructure)
    return function()
        local pack = BoosterPacks.default(setQuery)
        return packStructure(pack)
    end
end

BoosterPacks.standard = createCustomBooster('f:standard', function(pack)
    local url = config.apiBaseURL .. 'f:standard+'
    local artSets = '(set:tafr+or+set:tstx+or+set:tkhm+or+set:tznr+or+set:sznr+or+set:tm21+or+set:tiko+or+set:tthb+or+set:teld)'
    local artQuery = '(border:borderless+or+frame:showcase+or+frame:extendedart+or+set:plist+or+set:sta)'
    table.insert(pack, url .. 't:basic')
    table.insert(pack, config.apiBaseURL .. artSets)
    if math.random(2) == 1 then
        pack[#pack - 1] = url .. artQuery
    end
    if math.random(2) == 1 then
        pack[#pack] = url .. artQuery
    end
    return pack
end)

BoosterPacks.conspiracy = createCustomBooster('(s:cns+or+s:cn2)', function(pack)
    table.insert(pack, pack[#pack]:gsub('r:%S+', getRandomRarity(9, 6, 3)))
    pack[6] = pack[math.random(11, 12)]
    for i, _ in pairs(pack) do
        local query = (i == 6 or i == #pack) and '+wm:conspiracy' or '+-wm:conspiracy'
        pack[i] = pack[i] .. query
    end
    return pack
end)

BoosterPacks.innistrad = createCustomBooster('(s:isd+or+s:dka+or+s:avr+or+s:soi+or+s:emn+or+s:mid)', function(pack)
    table.insert(pack, pack[#pack]:gsub('r:%S+', getRandomRarity(8, 1)))
    pack[11] = pack[12]
    for i, _ in pairs(pack) do
        local query = (i == 6 or i == #pack or i == #pack - 2) and '+is:transform' or '+-is:transform'
        pack[i] = pack[i] .. query
    end
    return pack
end)

BoosterPacks.ravnica = createCustomBooster('(s:rav+or+s:gpt+or+s:dis+or+s:rtr+or+s:gtc+or+s:dgm+or+s:grn+or+s:rna)', function(pack)
    local landQuery = 't:land+-t:basic'
    table.insert(pack, pack[#pack])
    for i = 7, 9 do
        pack[i] = pack[6] .. '+id>=2'
    end
    for i, _ in pairs(pack) do
        if i == 6 or i == #pack then
            pack[i] = pack[i]:gsub('r:%S+', getRandomRarity(9, 6, 3)) .. '+' .. landQuery
        else
            pack[i] = pack[i] .. '+-' .. landQuery
        end
    end
    return pack
end)

-- Maps set codes that are not valid Lua identifiers to valid function names.
local setCodeMapping = {
    ['2xm'] = 'twoxm'
}

function getScryfallQueryTable()
    local setCode = string.lower(getSetCode())
    local mappedSetCode = setCodeMapping[setCode] or setCode
    local packGenerator = BoosterPacks[mappedSetCode] or BoosterPacks.default
    return packGenerator(setCode)
end

--- Scryfall API and Deck Handling ---
function fetchDeckData(urlTable, boosterID)
    local deck = {
        Transform = { posX = 0, posY = 0, posZ = 0, rotX = 0, rotY = 180, rotZ = 180, scaleX = 1, scaleY = 1, scaleZ = 1 },
        Name = "Deck",
        Nickname = getSetCode() .. " Booster",
        Description = cardStackDescription,
        DeckIDs = {},
        CustomDeck = {},
        ContainedObjects = {},
    }

    local requestsPending = #urlTable
    local requestsCompleted = 0

    for i, url in ipairs(urlTable) do
        WebRequest.get(url, function(request)
            if request.response_code ~= 200 then
                local errorInfo = JSON.decode(request.text)
                local message = errorInfo and errorInfo.details or (request.error .. ": " .. request.text)
                broadcastToAll(message, "Red")
                print(message)
            else
                local cardData = createCardDataFromJSON(request.text, i)
                if cardData then
                    deck.ContainedObjects[i] = cardData
                    deck.DeckIDs[i] = cardData.CardID
                    deck.CustomDeck[i] = cardData.CustomDeck[i]
                end
            end
            requestsCompleted = requestsCompleted + 1
        end)
    end

    Wait.condition(
            function()
                -- Guard against processing before all requests are complete
                if #deck.ContainedObjects ~= #urlTable then
                    return
                end

                local cardNames = {}
                local hasDuplicates = false
                for _, card in ipairs(deck.ContainedObjects) do
                    if cardNames[card.Nickname] then
                        hasDuplicates = true
                        break
                    end
                    cardNames[card.Nickname] = true
                end

                if hasDuplicates then
                    fetchDeckData(urlTable, boosterID)
                else
                    boosterDataCache[boosterID] = deck
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
            -- Split cards like Adventure
            cardName = getFormattedName(card.card_faces[1])
            for i, face in ipairs(card.card_faces) do
                cardOracle = cardOracle .. getFormattedName(face) .. '\n' .. getCardOracleText(face)
                if i < #card.card_faces then
                    cardOracle = cardOracle .. '\n'
                end
            end
            faceURL = card.image_uris.normal:gsub('%?.*', ''):gsub('normal', imageQuality) .. cacheBuster
        else
            -- Transform / DFC
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
        -- Normal card
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

