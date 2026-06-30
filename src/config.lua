local config = {
    backURL = 'https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-back.jpg',
    apiBaseURL = 'https://api.scryfall.com/cards/random?q=',
    searchBaseURL = 'https://api.scryfall.com/cards/search?order=set&unique=prints&q=',
    defaultPackImage = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/packs/----pack.png", -- same url used in packLua
    defaultSetCode = "???", -- same setCode used in packLua
    pollInterval = 1.2,
    rateLimitDelay = 60,
    requestStartupJitter = 3,
    imageLoadDelay = 0.1,
    imageProxyBaseURL = "https://images.weserv.nl/?url=",
    cacheChunkSize = 25,
    fastCacheChunkSize = 50,
    fastDeckChunkSize = 4,
}

return config
