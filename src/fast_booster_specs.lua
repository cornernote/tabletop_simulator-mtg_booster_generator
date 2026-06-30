-----------------------------------------------------------------------
-- FastBoosterSpecs - compact local booster recipes for one-set caches
-----------------------------------------------------------------------

local FastBoosterSpecs = {
    MKM = {
        name = "MKM Play Booster",
        cardCacheUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm.json",
        variants = {
            {
                weight = 28,
                slots = {
                    { pool = "land", count = 1 },
                    { pool = "common", count = 7 },
                    { pool = "uncommon", count = 3 },
                    { pool = "rareMythic", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 4,
                slots = {
                    { pool = "land", count = 1 },
                    { pool = "common", count = 6 },
                    { pool = "uncommon", count = 3 },
                    { pool = "rareMythic", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "theList", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 7,
                slots = {
                    { pool = "foilLand", count = 1 },
                    { pool = "common", count = 7 },
                    { pool = "uncommon", count = 3 },
                    { pool = "rareMythic", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
            {
                weight = 1,
                slots = {
                    { pool = "foilLand", count = 1 },
                    { pool = "common", count = 6 },
                    { pool = "uncommon", count = 3 },
                    { pool = "rareMythic", count = 1 },
                    { pool = "wildcard", count = 1 },
                    { pool = "theList", count = 1 },
                    { pool = "foil", count = 1 },
                },
            },
        },
    },
}

return FastBoosterSpecs
