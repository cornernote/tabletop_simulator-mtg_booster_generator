-----------------------------------------------------------------------
-- FastBoosterSpecs - compact local booster recipes for one-set caches
-----------------------------------------------------------------------

local FastBoosterSpecs = {
    MKM = {
        name = "MKM Play Booster",
        cardCacheBaseUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/",
        cardCacheParts = 26,
        variants = {
            {
                weight = 28,
                slots = {
                    { pool = "basic", count = 1 },
                    { pool = "commonWithShowcase", count = 7 },
                    { pool = "uncommonWithShowcase", count = 3 },
                    { pool = "rareMythicWithShowcase", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 4,
                slots = {
                    { pool = "basic", count = 1 },
                    { pool = "commonWithShowcase", count = 6 },
                    { pool = "uncommonWithShowcase", count = 3 },
                    { pool = "rareMythicWithShowcase", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "theList", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 7,
                slots = {
                    { pool = "foilBasic", count = 1 },
                    { pool = "commonWithShowcase", count = 7 },
                    { pool = "uncommonWithShowcase", count = 3 },
                    { pool = "rareMythicWithShowcase", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 1,
                slots = {
                    { pool = "foilBasic", count = 1 },
                    { pool = "commonWithShowcase", count = 6 },
                    { pool = "uncommonWithShowcase", count = 3 },
                    { pool = "rareMythicWithShowcase", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "theList", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
        },
    },
    MKMC = {
        name = "MKM Collector Booster",
        cardCacheBaseUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkmc/",
        cardCacheParts = 31,
        variants = {
            {
                weight = 183,
                slots = {
                    { pool = "foilCommon", count = 4 },
                    { pool = "foilUncommon", count = 3 },
                    { pool = "foilFullartBasic", count = 1 },
                    { pool = "commonUncommonShowcase", count = 1 },
                    { pool = "foilCommonUncommonShowcase", count = 1 },
                    { pool = "extendedCommanderRareMythic", count = 1 },
                    { pool = "extendedMainRareMythic", count = 1 },
                    { pool = "rareMythicShowcase", count = 1 },
                    { pool = "foilRareMythic", count = 1 },
                    { pool = "foilRareMythicShowcase", count = 1 },
                },
            },
            {
                weight = 17,
                slots = {
                    { pool = "foilCommon", count = 4 },
                    { pool = "foilUncommon", count = 3 },
                    { pool = "foilFullartBasic", count = 1 },
                    { pool = "commonUncommonShowcase", count = 1 },
                    { pool = "foilCommonUncommonShowcase", count = 1 },
                    { pool = "foilExtendedCommanderRareMythic", count = 1 },
                    { pool = "extendedMainRareMythic", count = 1 },
                    { pool = "rareMythicShowcase", count = 1 },
                    { pool = "foilRareMythic", count = 1 },
                    { pool = "foilRareMythicShowcase", count = 1 },
                },
            },
        },
    },
}

return FastBoosterSpecs
