# MTG Booster Types

Generated: 2026-06-30. This is a taxonomy note for the booster generator. It records the product families we need to think about before adding more exact `set_definitions` or fast-cache specs.

## Sources

- Local inventory: `docs/mtg-booster-inventory.csv`, generated from MTGJSON per-set booster configs.
- Current WotC product language: https://magic.wizards.com/en/product-guide
- MTG Wiki overview pages: https://mtg.fandom.com/wiki/Booster_pack, https://mtg.fandom.com/wiki/Play_Booster, https://mtg.fandom.com/wiki/Set_Booster

## Current Store-Facing Booster Families

| Type | What it means | Generator implication |
| --- | --- | --- |
| Play Booster | Current main booster for drafting and pack opening. At least one rare/mythic and at least one foil; set-specific special slots vary. | High priority. This should be the default modern fast-cache target. |
| Collector Booster | Premium booster with many foils/special treatments and several rare-or-higher cards. | Needs exact per-set specs; not safe to approximate with simple rarity slots if accuracy matters. |
| Jumpstart Booster | Themed 20-card half-deck with lands included. | Different model from normal boosters; should generate a coherent theme pack, not random rarity slots. |
| Draft Booster | Traditional limited booster used before Play Boosters and still present in older sets/products. | Important historical target; era-specific slots are needed. |
| Set Booster | Opening-focused booster used before Play Boosters. | Can be supported, but art cards/tokens/List slots need decisions. |
| Collector Booster Sample Pack | Usually a small 2-card sample included with other products. | Probably optional; useful only if we model sealed products/Commander deck extras. |

## Implementation Families Seen In MTGJSON

These are the normalized families in `mtg-booster-inventory.csv`. Counts are booster config rows, not sets.

| Family | Rows | Common raw keys | Notes |
| --- | ---: | --- | --- |
| play | 17 | `play` | Modern draft/opening booster introduced as the unified replacement for Draft and Set Boosters. Current generator priority. |
| collector | 50 | `collector, collector-jp, collector-special` | Premium booster focused on foils, showcase/borderless/extended-art treatments, and multiple rares/mythics. |
| collector-sample | 18 | `collector-sample` | Small 2-card sample boosters commonly packed inside Commander decks or other sealed products. |
| draft/default | 165 | `draft, default, jp` | Traditional limited booster. Includes old default boosters and named draft configs; exact slot model changes by era. |
| set | 19 | `set, set-jp` | Opening-focused booster used before Play Boosters; commonly includes art card, wildcard slots, foil, and The List chance. |
| theme | 87 | `theme-b, theme-g, theme-r, theme-u, theme-w, theme-boros, theme-dimir, theme-golgari, theme-izzet, theme-selesnya, theme-azorius, theme-gruul, ...` | Color/faction/theme-focused large boosters, generally not for draft. Includes guild, color, party, school, and creature-theme variants. |
| jumpstart | 11 | `jumpstart, jumpstart-v2` | 20-card themed half-decks intended to shuffle two packs together and play. |
| starter/tournament | 22 | `tournament, starter` | Old starter/tournament pack configurations, usually much larger sealed packs with multiple rares and many commons/uncommons/lands. |
| six-card/sample | 19 | `six` | Small six-card boosters or sample-style product configs. |
| prerelease/promo | 72 | `prerelease, prerelease-azorius, prerelease-golgari, prerelease-izzet, prerelease-rakdos, prerelease-selesnya, prerelease-boros, prerelease-dimir, prerelease-gruul, prerelease-orzhov, prerelease-simic, prerelease-atarka, ...` | Seeded prerelease packs, promo slots, guild/clan/faction prerelease boosters, and prerelease promo configs. |
| promo/bundle/topper | 19 | `box-topper, duelspromo, bundle-promo, box-topper-foil, gift-bundle-promo, chocobo-bundle, chocobo-bundle-scene` | Bundle promos, box toppers, gift bundle promos, scene/chocobo bundle inserts, and similar non-normal booster inserts. |
| special/other | 44 | `fat-pack, premium, fate, treasure-chest, convention, convention-2021, baseball-signed, blueprint-mk1, blueprint-mk2, chaos-emeralds, deceptive-districts, dnd-50th-anniversary, ...` | Oddball paper configs such as fat-pack inserts, VIP, convention/mystery variants, compleat, treasure chest-like or Secret Lair style configs. |
| digital-arena | 39 | `arena, arena-1, arena-2, arena-3, arena-4, play-arena` | Arena-only booster configs; useful for completeness but not paper booster generation by default. |
| digital-mtgo | 6 | `mtgo` | Magic Online-only booster configs such as Masters Edition/Vintage Masters/Tempest Remastered MTGO packs. |

## Raw Booster Keys Seen

These are the exact `booster_key` values currently present in the inventory, grouped by normalized family. This is useful when mapping MTGJSON configs to generator modes.

### play
`play` (17)

### collector
`collector` (48), `collector-jp` (1), `collector-special` (1)

### collector-sample
`collector-sample` (18)

### draft/default
`draft` (135), `default` (27), `jp` (3)

### set
`set` (18), `set-jp` (1)

### theme
`theme-b` (12), `theme-g` (12), `theme-r` (12), `theme-u` (12), `theme-w` (12), `theme-boros` (1), `theme-dimir` (1), `theme-golgari` (1), `theme-izzet` (1), `theme-selesnya` (1), `theme-azorius` (1), `theme-gruul` (1), `theme-orzhov` (1), `theme-rakdos` (1), `theme-simic` (1), `theme-monsters` (1), `theme-party` (1), `theme-vikings` (1), `theme-lorehold` (1), `theme-prismari` (1), `theme-quandrix` (1), `theme-silverquill` (1), `theme-witherbloom` (1), `theme-dungeons` (1), `theme-werewolves` (1), `theme-vampires` (1), `theme-ninjas` (1), `theme-brokers` (1), `theme-cabaretti` (1), `theme-maestros` (1), `theme-obscura` (1), `theme-riveteers` (1)

### jumpstart
`jumpstart` (10), `jumpstart-v2` (1)

### starter/tournament
`tournament` (13), `starter` (9)

### six-card/sample
`six` (19)

### prerelease/promo
`prerelease` (52), `prerelease-azorius` (1), `prerelease-golgari` (1), `prerelease-izzet` (1), `prerelease-rakdos` (1), `prerelease-selesnya` (1), `prerelease-boros` (1), `prerelease-dimir` (1), `prerelease-gruul` (1), `prerelease-orzhov` (1), `prerelease-simic` (1), `prerelease-atarka` (1), `prerelease-dromoka` (1), `prerelease-kolaghan` (1), `prerelease-ojutai` (1), `prerelease-silumgar` (1), `prerelease-brokers` (1), `prerelease-cabaretti` (1), `prerelease-maestros` (1), `prerelease-obscura` (1), `prerelease-riveteers` (1)

### promo/bundle/topper
`box-topper` (11), `duelspromo` (2), `bundle-promo` (2), `box-topper-foil` (1), `gift-bundle-promo` (1), `chocobo-bundle` (1), `chocobo-bundle-scene` (1)

### special/other
`fat-pack` (19), `premium` (1), `fate` (1), `treasure-chest` (1), `convention` (1), `convention-2021` (1), `baseball-signed` (1), `blueprint-mk1` (1), `blueprint-mk2` (1), `chaos-emeralds` (1), `deceptive-districts` (1), `dnd-50th-anniversary` (1), `fin-elementals` (1), `spider-man` (1), `stainedglass-b` (1), `stainedglass-c` (1), `stainedglass-g` (1), `stainedglass-iwd` (1), `stainedglass-r` (1), `stainedglass-tattoo` (1), `stainedglass-u` (1), `stainedglass-uncommon` (1), `stainedglass-w` (1), `vip` (1), `compleat` (1), `beginner` (1)

### digital-arena
`arena` (31), `arena-1` (2), `arena-2` (2), `arena-3` (2), `arena-4` (1), `play-arena` (1)

### digital-mtgo
`mtgo` (6)

## Scope Recommendation

For the booster generator, support should probably land in this order:

1. Play Boosters for modern/future sets, using prebuilt chunked caches and per-set slot specs.
2. Draft/default boosters for historical sets, grouped by era and overridden by exact MTGJSON sheets where needed.
3. Collector Boosters for sets where we have exact slot specs and care about premium pack opening.
4. Jumpstart, because it needs theme-pack logic instead of rarity-slot logic.
5. Set Boosters and Theme Boosters, which are less important for draft but useful for pack-opening simulation.
6. Prerelease, sample, bundle/topper, starter/tournament, Arena, and MTGO configs as optional/advanced modes.

## Notes

- WotC product names and MTGJSON config keys do not line up one-to-one. Example: older sets often use `default`, while newer sets use `draft`, `set`, `collector`, or `play`.
- Some configs are inserts or sealed-product contents rather than normal boosters. Treat `promo/bundle/topper`, `collector-sample`, and many `prerelease/promo` entries as optional modes.
- Digital configs are retained for completeness but should not be default paper generation behavior.
