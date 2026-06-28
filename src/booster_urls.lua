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
