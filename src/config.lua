local config = {
    backURL = 'https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/',
    apiBaseURL = 'https://api.scryfall.com/cards/random?q=',
    searchBaseURL = 'https://api.scryfall.com/cards/search?order=set&unique=prints&q=',
    defaultPackImage = "https://steamusercontent-a.akamaihd.net/ugc/12555777445170015064/1F22F21DA19B1C5D668D761C2CA447889AE98A2A/", -- same url used in packLua
    defaultSetCode = "???", -- same setCode used in packLua
    pollInterval = 1.2,
    rateLimitDelay = 60,
    requestStartupJitter = 3,
    imageLoadDelay = 0.1,
    imageProxyBaseURL = "https://images.weserv.nl/?url=",
    cacheChunkSize = 25,
}

return config
