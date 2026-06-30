-----------------------------------------------------------------------
-- SetDefinitions - defines the booster set name, contents, etc
-----------------------------------------------------------------------

local PACK_IMAGE_BASE_URL = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/packs/"

local function packImage(code, variant)
    local lowerCode = string.lower(code)
    if lowerCode == "---" then
        return PACK_IMAGE_BASE_URL .. "----pack.png"
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
        name = "Avatar: The Last Airbender",
        date = "2025-11-21",
        getUrls = BoosterUrls.default14CardPack,
    },
    TLAC = {
        name = "Avatar: The Last Airbender Collector",
        date = "2025-11-21",
        getUrls = function(set)
            return BoosterUrls.default15CardPack({ "TLA", "TLE" })
        end,
    },
    SPM = {
        name = "Marvel's Spider-Man",
        date = "2025-09-26",
        getUrls = function(set)
            return BoosterUrls.default14CardPack({ "SPM", "MAR" })
        end,
    },
    SPMC = {
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
        name = "Final Fantasy",
        date = "2025-06-13",
        getUrls = function(set)
            return BoosterUrls.default14CardPack({ "FIN", "FCA" })
        end,
    },
    FINC = {
        name = "Final Fantasy Collector",
        date = "2025-06-13",
        getUrls = function(set)
            return BoosterUrls.default15CardPack({ "FIN", "FCA", "FIC" })
        end,
    },
    BOK = {
        name = "Betrayers of Kamigawa",
        date = "2005-02-04",
        getUrls = function(set)
            local urls = BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
            urls[15] = urls[15]:gsub("r:m", "r:r")
            return urls
        end,
    },
    CHK = {
        name = "Champions of Kamigawa",
        date = "2004-10-01",
    },
    PIO = {
        name = "Pioneer Masters",
        date = "2024-12-10",
        getUrls = BoosterUrls.default14CardPack,
    },
    INR = {
        name = "Innistrad Remaster",
        date = "2025-01-24",
        getUrls = BoosterUrls.default14CardPack,
    },
    DFT = {
        name = "Aetherdrift",
        date = "2025-02-14",
        getUrls = BoosterUrls.default14CardPack,
    },
    EOE = {
        name = "Edge of Eternities",
        date = "2025-08-01",
        getUrls = BoosterUrls.default14CardPack,
    },
    TDM = {
        name = "Tarkir: Dragonstorm",
        date = "2025-04-11",
        getUrls = BoosterUrls.default14CardPack,
    },
    FDN = {
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
        name = "Duskmourn: House of Horror",
        date = "2024-09-27",
        getUrls = BoosterUrls.default14CardPack,
    },
    BLB = {
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
        name = "Murders at Karlov Manor",
        date = "2024-02-09",
        getUrls = BoosterUrls.default14CardPack,
    },
    MKMC = {
        name = "Murders at Karlov Manor Collector",
        date = "2024-02-09",
        getUrls = function(set)
            return BoosterUrls.default15CardPack("MKM")
        end,
    },
    OTJ = {
        name = "Outlaws of Thunder Junction",
        date = "2024-04-19",
        getUrls = BoosterUrls.default14CardPack,
    },
    RVR = {
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
        name = "Ixalan",
        date = "2023-11-17",
    },
    MID = {
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
        date = "2021-07-23",
    },
    CMB1 = {
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
        name = "Unstable",
        date = "2017-12-08",
    },
    UGL = {
        name = "Unglued",
        date = "1998-08-11",
    },
    UNH = {
        name = "Unhinged",
        date = "2004-11-19",
    },
    VOW = {
        name = "Innistrad: Crimson Vow",
        date = "2021-11-19",
    },
    UMA = {
        name = "Ultimate Masters",
        date = "2018-12-07",
    },
    CMM = {
        name = "Commander Masters",
        date = "2023-08-04",
        getUrls = BoosterUrls.default20CardPack,
    },
    MMA = {
        name = "Modern Masters",
        date = "2013-06-07",
        getUrls = function(set)
            return BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
        end,
    },
    SOK = {
        name = "Saviors of Kamigawa",
        date = "2005-06-03",
        getUrls = function(set)
            return BoosterUrls.swapLandForCommon(BoosterUrls.default15CardPack(set))
        end,
    },
    NEO = {
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
        name = "Kaldheim",
        date = "2021-02-05",
    },
    LEA = {
        name = "Limited Edition Alpha",
        date = "1993-08-05",
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
    name = "Double Masters",
    date = "2020-08-07",
    getUrls = BoosterUrls.default16CardPack,
}

local generatedPackImageCodes = {
    "TRK", "FRA", "HOB", "MSH", "SOS", "TMT", "ECL",
    "TLA", "TLAC", "SPM", "SPMC", "OM1", "FIN", "FINC", "EOE", "TDM", "DFT", "INR",
    "PIO", "FDN", "J25", "DSK", "BLB", "MB2", "ACR", "MH3", "BIG", "OTJ", "CLU", "MKM", "MKMC", "RVR",
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
