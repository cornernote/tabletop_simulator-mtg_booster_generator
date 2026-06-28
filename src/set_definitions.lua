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
