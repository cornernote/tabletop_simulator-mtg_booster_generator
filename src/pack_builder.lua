-----------------------------------------------------------------------
-- PackBuilder - fetches card info and builds a booster pack
-----------------------------------------------------------------------

local FastBoosterSpecs = require("fast_booster_specs")

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

PackBuilder.hasFastBoosterSpec = function(setCode)
    return FastBoosterSpecs[setCode] ~= nil
end

PackBuilder.cardIsBasicLand = function(card)
    return PackBuilder.cardHasType(card, "Basic") and PackBuilder.cardHasType(card, "Land")
end

PackBuilder.buildFastBoosterPools = function(cards)
    local pools = {
        land = {},
        common = {},
        uncommon = {},
        rareMythic = {},
        wildcard = {},
        foil = {},
    }

    for _, card in ipairs(cards) do
        local isBasicLand = PackBuilder.cardIsBasicLand(card)
        if isBasicLand then
            table.insert(pools.land, card)
        elseif card.rarity == "common" then
            table.insert(pools.common, card)
            table.insert(pools.wildcard, card)
        elseif card.rarity == "uncommon" then
            table.insert(pools.uncommon, card)
            table.insert(pools.wildcard, card)
        elseif card.rarity == "rare" or card.rarity == "mythic" then
            table.insert(pools.rareMythic, card)
            table.insert(pools.wildcard, card)
        end

        if not isBasicLand then
            table.insert(pools.foil, card)
        end
    end

    pools.foilLand = pools.land
    pools.theList = pools.wildcard
    return pools
end

PackBuilder.addCardToFastPools = function(pools, card)
    local isBasicLand = PackBuilder.cardIsBasicLand(card)
    if isBasicLand then
        table.insert(pools.land, card)
    elseif card.rarity == "common" then
        table.insert(pools.common, card)
        table.insert(pools.wildcard, card)
    elseif card.rarity == "uncommon" then
        table.insert(pools.uncommon, card)
        table.insert(pools.wildcard, card)
    elseif card.rarity == "rare" or card.rarity == "mythic" then
        table.insert(pools.rareMythic, card)
        table.insert(pools.wildcard, card)
    end

    if not isBasicLand then
        table.insert(pools.foil, card)
    end
end

PackBuilder.buildFastBoosterPoolsAsync = function(cards, done)
    local pools = {
        land = {},
        common = {},
        uncommon = {},
        rareMythic = {},
        wildcard = {},
        foil = {},
    }
    local index = 1

    local function processChunk()
        local last = math.min(#cards, index + config.fastCacheChunkSize - 1)
        for i = index, last do
            PackBuilder.addCardToFastPools(pools, cards[i])
        end
        index = last + 1
        if index <= #cards then
            Wait.time(processChunk, 0.01)
        else
            pools.foilLand = pools.land
            pools.theList = pools.wildcard
            done(pools)
        end
    end

    processChunk()
end

PackBuilder.chooseWeightedFastVariant = function(spec)
    local total = 0
    for _, variant in ipairs(spec.variants) do
        total = total + variant.weight
    end

    local roll = math.random(total)
    for _, variant in ipairs(spec.variants) do
        roll = roll - variant.weight
        if roll <= 0 then
            return variant
        end
    end
    return spec.variants[#spec.variants]
end

PackBuilder.chooseFastPoolCard = function(pool, seenNames)
    if not pool or #pool == 0 then
        if not pool or not pool.cards or #pool.cards == 0 then
            return nil
        end

        local candidates = {}
        local totalWeight = 0
        for _, entry in ipairs(pool.cards) do
            if entry.card and not seenNames[entry.card.name] then
                table.insert(candidates, entry)
                totalWeight = totalWeight + entry.weight
            end
        end
        if #candidates == 0 then
            candidates = pool.cards
            totalWeight = pool.totalWeight
        end

        local roll = math.random(totalWeight)
        for _, entry in ipairs(candidates) do
            roll = roll - entry.weight
            if roll <= 0 then
                return entry.card
            end
        end
        return candidates[#candidates].card
    end

    local unseen = {}
    for _, card in ipairs(pool) do
        if not seenNames[card.name] then
            table.insert(unseen, card)
        end
    end
    if #unseen > 0 then
        pool = unseen
    end
    return pool[math.random(1, #pool)]
end

PackBuilder.resolveFastSheetPools = function(cardMap, sheets)
    local pools = {}
    for sheetName, sheet in pairs(sheets or {}) do
        local pool = { cards = {}, totalWeight = 0, foil = sheet.foil }
        for _, entry in ipairs(sheet.cards or {}) do
            local card = cardMap[entry.id]
            if card then
                local weight = entry.weight or 1
                table.insert(pool.cards, { card = card, weight = weight })
                pool.totalWeight = pool.totalWeight + weight
            end
        end
        pools[sheetName] = pool
    end
    return pools
end

PackBuilder.buildFastDeck = function(setCode, spec)
    local cards = data.setCaches[setCode] or {}
    local pools = PackBuilder.buildFastBoosterPools(cards)
    local variant = PackBuilder.chooseWeightedFastVariant(spec)
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
    local cardIndex = 1

    for _, slot in ipairs(variant.slots) do
        local pool = pools[slot.pool] or {}
        for _ = 1, slot.count do
            local card = PackBuilder.chooseFastPoolCard(pool, seenNames)
            if card then
                seenNames[card.name] = true
                local cardData = PackBuilder.createCardData(card, cardIndex)
                deck.ContainedObjects[cardIndex] = cardData
                deck.DeckIDs[cardIndex] = cardData.CardID
                deck.CustomDeck[cardIndex] = cardData.CustomDeck[cardIndex]
                cardIndex = cardIndex + 1
            else
                table.insert(requestErrors, { url = setCode .. ":" .. slot.pool, message = "No cached cards matched this fast booster slot." })
            end
        end
    end

    return deck, requestErrors
end

PackBuilder.buildFastDeckAsync = function(setCode, spec, done)
    local cards = data.setCaches[setCode] or {}
    local exactPools = data.fastSheetCaches[setCode]

    local function buildDeckFromPools(pools)
        local variant = PackBuilder.chooseWeightedFastVariant(spec)
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
        local cardIndex = 1
        local plannedSlots = {}

        for _, slot in ipairs(variant.slots) do
            for _ = 1, slot.count do
                table.insert(plannedSlots, slot.pool)
            end
        end

        local slotIndex = 1
        local function processDeckChunk()
            local last = math.min(#plannedSlots, slotIndex + config.fastDeckChunkSize - 1)
            for i = slotIndex, last do
                local poolName = plannedSlots[i]
                local card = PackBuilder.chooseFastPoolCard(pools[poolName] or {}, seenNames)
                if card then
                    seenNames[card.name] = true
                    local cardData = PackBuilder.createCardData(card, cardIndex)
                    deck.ContainedObjects[cardIndex] = cardData
                    deck.DeckIDs[cardIndex] = cardData.CardID
                    deck.CustomDeck[cardIndex] = cardData.CustomDeck[cardIndex]
                    cardIndex = cardIndex + 1
                else
                    table.insert(requestErrors, { url = setCode .. ":" .. poolName, message = "No cached cards matched this fast booster slot." })
                end
            end
            slotIndex = last + 1
            if slotIndex <= #plannedSlots then
                Wait.time(processDeckChunk, 0.01)
            else
                done(deck, requestErrors)
            end
        end

        processDeckChunk()
    end

    if exactPools then
        buildDeckFromPools(exactPools)
    else
        PackBuilder.buildFastBoosterPoolsAsync(cards, buildDeckFromPools)
    end
end

PackBuilder.finishFastSetCacheLoad = function(setCode, loadState, error, source)
    data.fastSetCacheLoads[setCode] = nil
    for _, callback in ipairs(loadState.callbacks) do
        callback(error, source)
    end
end

PackBuilder.loadPrebuiltSetCache = function(setCode, spec, leaveObject, callback)
    if data.setCaches[setCode] then
        callback(nil, "memory")
        return
    end
    local urls = spec.cardCacheUrls or (spec.cardCacheUrl and { spec.cardCacheUrl }) or nil
    if not urls and spec.cardCacheBaseUrl and spec.cardCacheParts then
        urls = {}
        for i = 1, spec.cardCacheParts do
            table.insert(urls, spec.cardCacheBaseUrl .. string.format("%03d.json", i))
        end
    end
    if not urls or #urls == 0 then
        callback("No prebuilt card cache URL configured.")
        return
    end

    local loadState = data.fastSetCacheLoads[setCode]
    if loadState then
        table.insert(loadState.callbacks, callback)
        return
    end

    loadState = { callbacks = { callback }, leaveObject = leaveObject }
    data.fastSetCacheLoads[setCode] = loadState

    local cardList = {}
    local cardMap = {}
    local sheets = {}
    local partIndex = 1

    local function loadNextPart()
        local url = urls[partIndex]
        if not url then
            data.setCaches[setCode] = cardList
            if next(sheets) then
                data.fastSheetCaches[setCode] = PackBuilder.resolveFastSheetPools(cardMap, sheets)
            end
            PackBuilder.printDebug("loaded prebuilt cache: " .. setCode .. " (" .. #cardList .. " cards in " .. #urls .. " parts)")
            PackBuilder.finishFastSetCacheLoad(setCode, loadState, nil, "prebuilt")
            return
        end

        PackBuilder.editStatusButton(leaveObject, "prebuilt " .. partIndex .. "/" .. #urls)

        local function handleResponse(request)
            if PackBuilder.isRateLimitedResponse(request) then
                PackBuilder.startRateLimitCooldown(url, handleResponse, leaveObject)
                return
            end

            if request.response_code == 200 then
                local ok, decoded = pcall(function()
                    return JSON.decode(request.text)
                end)
                if not ok then
                    PackBuilder.finishFastSetCacheLoad(setCode, loadState, "Prebuilt cache JSON could not be decoded.")
                    return
                end
                local decodedCards = decoded and decoded.cards
                if type(decodedCards) == "table" and #decodedCards > 0 then
                    for _, card in ipairs(decodedCards) do
                        table.insert(cardList, card)
                    end
                elseif type(decodedCards) == "table" then
                    for id, card in pairs(decodedCards) do
                        cardMap[id] = card
                        table.insert(cardList, card)
                    end
                elseif decoded and decoded.name then
                    table.insert(cardList, decoded)
                elseif type(decoded) == "table" and not decoded.sheets then
                    for _, card in ipairs(decoded) do
                        table.insert(cardList, card)
                    end
                end

                if decoded and type(decoded.sheets) == "table" then
                    for sheetName, sheet in pairs(decoded.sheets) do
                        sheets[sheetName] = sheet
                    end
                end

                if #cardList > 0 or next(sheets) then
                    partIndex = partIndex + 1
                    Wait.time(loadNextPart, 0.01)
                    return
                end
                PackBuilder.finishFastSetCacheLoad(setCode, loadState, "Prebuilt cache did not contain cards.")
                return
            end

            local message = request.error or ("HTTP " .. tostring(request.response_code))
            if request.text and request.text ~= "" then
                local ok, errorInfo = pcall(function()
                    return JSON.decode(request.text)
                end)
                errorInfo = ok and errorInfo or nil
                message = errorInfo and errorInfo.details or message
            end
            PackBuilder.finishFastSetCacheLoad(setCode, loadState, message)
        end

        PackBuilder.enqueueRequest(url, handleResponse, "end")
    end

    loadNextPart()
end

PackBuilder.buildFastDeckContents = function(boosterID, setCode, spec)
    local boosterContents = {}
    PackBuilder.buildFastDeckAsync(setCode, spec, function(deck, requestErrors)
        table.insert(boosterContents, deck)
        for _, requestError in ipairs(requestErrors) do
            table.insert(boosterContents, PackBuilder.generateErrorNotecard(requestError))
        end
        PackBuilder.cache[boosterID] = boosterContents
    end)
end

PackBuilder.fetchDeckDataFast = function(boosterID, setCode, leaveObject)
    local spec = FastBoosterSpecs[setCode]
    if not spec then
        return false
    end

    PackBuilder.editStatusButton(leaveObject, "prebuilt cache")
    PackBuilder.loadPrebuiltSetCache(setCode, spec, leaveObject, function(error)
        if not error then
            PackBuilder.editStatusButton(leaveObject, "fast build")
            PackBuilder.buildFastDeckContents(boosterID, setCode, spec)
            return
        end

        PackBuilder.printDebug("prebuilt cache failed for " .. setCode .. ": " .. tostring(error) .. "; falling back to Scryfall")
        PackBuilder.editStatusButton(leaveObject, "scryfall cache")
        PackBuilder.loadSetCache(setCode, leaveObject, function(fallbackError)
            local boosterContents = {}
            if fallbackError then
                table.insert(boosterContents, PackBuilder.generateErrorNotecard({ url = setCode, message = fallbackError }))
                PackBuilder.cache[boosterID] = boosterContents
                return
            end

            PackBuilder.editStatusButton(leaveObject, "fast build")
            PackBuilder.buildFastDeckContents(boosterID, setCode, spec)
        end)
    end)
    return true
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
