-----------------------------------------------------------------------
-- FastBoosterSpecs - compact local booster recipes for one-set caches
-----------------------------------------------------------------------

local FastBoosterSpecs = {
    MKM = {
        name = "MKM Play Booster",
        cardCacheUrls = {
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/001.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/002.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/003.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/004.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/005.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/006.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/007.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/008.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/009.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/010.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/011.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/012.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/013.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/014.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/015.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/016.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/017.json",
            "https://raw.githubusercontent.com/cornernote/tabletop_simulator-mtg_booster_generator/main/assets/card-caches/mkm/018.json",
        },
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
