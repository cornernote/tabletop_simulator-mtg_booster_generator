# MTG Booster Release and Slot-Spec Research

Generated: 2026-06-29 from online sources. Scope is Magic: The Gathering booster-like products released by Wizards of the Coast through 2026-06-29. I did not add anything to `src/set_definitions.lua`.

## Deliverables

- `docs/mtg-booster-inventory.csv` is the exhaustive machine-readable inventory. It has one row per MTGJSON booster config, including set code, release date, delivery (`paper`, `mtgo`, or `arena`), product/config key, family, weighted variant count, slot recipe, sheet names, and source URL.
- This Markdown file is the readable research brief and implementation map.

## Source Strategy

Primary data spine:

- MTGJSON per-set files, using each set's `booster` object. MTGJSON documents `booster` as a set property containing `boosters`, `boostersTotalWeight`, `sheets`, and `sourceSetCodes`: https://mtgjson.com/data-models/booster/booster-config/
- MTGJSON sheet definitions identify the actual weighted card pools and sheet behavior such as duplicate allowance, color balancing, fixed sheets, foil flag, and total weight: https://mtgjson.com/data-models/booster/booster-sheet/
- MTGJSON sealed content project tracks physical sealed product contents and feeds daily MTGJSON builds: https://github.com/mtgjson/mtg-sealed-content

Cross-check / vocabulary sources:

- MTG Wiki booster pack overview for historical product families and generic Draft/Theme/Collector/Set/Play descriptions: https://mtg.fandom.com/wiki/Booster_pack
- MTG Wiki Play Booster slot overview: https://mtg.fandom.com/wiki/Play_Booster
- MTG Wiki Set Booster overview: https://mtg.fandom.com/wiki/Set_Booster
- Wizards product guide for current product family summaries: https://magic.wizards.com/en/product-guide
- Scryfall set/card APIs remain useful for implementation queries and set/card coverage, but Scryfall does not expose full booster collation specs in the same way MTGJSON does: https://scryfall.com/docs/api/sets

## Inventory Summary

- MTGJSON set files fetched: 865
- Sets with at least one booster config: 198
- Booster config rows in CSV: 588
- Released booster config rows through 2026-06-29: 588
- Released paper booster config rows through 2026-06-29: 543
- Released paper sets with booster configs: 188
- Current `set_definitions.lua` entries overlapping released paper sets: 53
- Released paper sets with MTGJSON booster configs not explicitly in `set_definitions.lua`: 135

Delivery counts for released configs:

| Delivery | Config rows |
| --- | ---: |
| arena | 39 |
| mtgo | 6 |
| paper | 543 |

Family counts for released configs:

| Family | Config rows |
| --- | ---: |
| collector | 50 |
| collector-sample | 18 |
| digital-arena | 39 |
| digital-mtgo | 6 |
| draft/default | 165 |
| jumpstart | 11 |
| play | 17 |
| prerelease/promo | 72 |
| promo/bundle/topper | 19 |
| set | 19 |
| six-card/sample | 19 |
| special/other | 44 |
| starter/tournament | 22 |
| theme | 87 |


## Implementation Notes

- The generator's current `BoosterUrls` model can express simple rarity-slot packs, but the MTGJSON data shows many boosters need weighted variant packs and named sheets. The clean future shape is probably a small MTGJSON-inspired slot engine rather than hand-coded one-off Lua functions for every set.
- For draft/default packs, historical eras matter: early boosters have no basic land slot, Fallen Empires is 8 cards, Ice Age/Mirage-era starters/tournament packs exist, foils begin as weighted replacements, mythic rare starts with Shards of Alara, and Play Boosters replace Draft/Set Boosters starting with Murders at Karlov Manor.
- Collector, Set, Theme, Jumpstart, Prerelease, sample, bundle, and box-topper configs are in the inventory. We should decide which of those are in-scope for actual generation before adding definitions.
- Digital-only Arena and Magic Online configs are retained in the CSV with `delivery=arena` or `delivery=mtgo` so they can be filtered out or intentionally supported.
- `token`, `marketing`, and art-card/nonplayable objects are not always represented as normal card slots in these configs. For Tabletop Simulator booster generation, we may intentionally skip nonplayable inserts unless the set has Scryfall records we want to surface.

## Current Coverage Gaps

Released paper set codes in MTGJSON but not explicitly covered in `set_definitions.lua`:

10E, 2ED, 2X2, 30A, 3ED, 4ED, 5DN, 5ED, 6ED, 7ED, 8ED, 9ED, A25, AER, AKH, ALA, APC, ARB, ARN, ATQ, AVR, BBD, BFZ, BNG, BRO, CHR, CLB, CMR, CON, DBL, DGM, DIS, DMR, DMU, DRK, DST, DTK, ELD, EMA, EVE, EXO, FEM, FRF, FUT, GPT, GRN, GTC, HML, HOU, IKO, IMA, INV, J22, JMP, JOU, JUD, KLD, KTK, LCI, LEB, LEG, LGN, LRW, LTR, M10, M11, M12, M13, M14, M15, M19, M20, M21, MAT, MB1, MBS, MH2, MIR, MM2, MM3, MMQ, MOM, MOR, MRD, NEM, NPH, ODY, OGW, ONE, ONS, ORI, P02, PCY, PIP, PLC, PLS, POR, PTK, RAV, REN, RIN, RIX, RNA, ROE, RTR, S99, SCG, SHM, SLD, SNC, SOM, SS1, SS2, SS3, STH, SUM, THB, THS, TLE, TMP, ... +15 more

Entries currently in `set_definitions.lua` that are not released MTGJSON booster-config sets under this filter, often future/planned, digital, collector aliases, or custom aliases:

BIG, CMB1, FINC, FRA, HOB, OM1, SPMC, TLAC, TRK

## Era Examples

These examples show why the CSV keeps exact weighted variants. Long recipes are truncated here; use the CSV for full slot specs.

| Set | Booster key | Family | Variants | Recipe preview |
| --- | --- | --- | ---: | --- |
| LEA | default | draft/default | 1 | w1: common x11 + rare x1 + uncommon x3 |
| LEA | starter | starter/tournament | 1 | w1: commonWithDuplicates x45 + rare x2 + uncommonWithDuplicates x13 |
| FEM | default | draft/default | 1 | w1: common x6 + uncommon x2 |
| ICE | default | draft/default | 1 | w1: common x11 + rare x1 + uncommon x3 |
| ICE | starter | starter/tournament | 1 | w1: basicWithDuplicates x22 + commonWithDuplicates x26 + rare x3 + uncommonWithDuplicates x9 |
| MIR | draft | draft/default | 1 | w1: common x11 + rare x1 + uncommon x3 |
| MIR | starter | starter/tournament | 1 | w1: basics x22 + commonWithDuplicates x25 + rare x3 + uncommonWithDuplicates x10 |
| USG | draft | draft/default | 1 | w1: common x11 + rare x1 + uncommon x3 |
| USG | tournament | starter/tournament | 1 | w1: basicWithDuplicates x30 + commonWithDuplicates x32 + rare x3 + uncommonWithDuplicates x10 |
| INV | draft | draft/default | 8 | w854667: common x11 + rare x1 + uncommon x3 / w105633: common x10 + foilCommonOrBasic x1 + rare x1 + uncommon x3 / w26433: common x11 + foilUncommon x1 + rare x1 + uncommon x2 / w3267: common x10 + foilCommonOrBasic x1 + foilUncommon x1 + rare x1 + uncommon x2 / w8633: common x11 + foilRare x1 + uncommon x3 / w1067: common x10 + foilCommonOrBasic x1 + foilRare x1 + uncommon x3 / w267: common x11 + foilRare x1 + foilUncommon x1 + uncommon x2 / w33: common x10 + foilCommonOrBasic x1 + foilRare x1  |
| INV | tournament | starter/tournament | 1 | w1: basic x30 + commonWithDuplicates x32 + rare x3 + uncommonWithDuplicates x10 |
| ALA | draft | draft/default | 2 | w31: basic x1 + common x10 + rareMythic x1 + uncommon x3 / w9: basic x1 + common x9 + foil x1 + rareMythic x1 + uncommon x3 |
| ALA | tournament | starter/tournament | 1 | w1: basic x29 + common x33 + rare x3 + uncommon x10 |
| ISD | draft | draft/default | 2 | w31: basic x1 + dfc x1 + sfcCommon x9 + sfcRareMythic x1 + sfcUncommon x3 / w9: basic x1 + dfc x1 + foil x1 + sfcCommon x8 + sfcRareMythic x1 + sfcUncommon x3 |
| TSP | draft | draft/default | 2 | w31: common x10 + rare x1 + tsts x1 + uncommon x3 / w9: common x9 + foil x1 + rare x1 + tsts x1 + uncommon x3 |
| ELD | collector | collector | 6 | w70: ancillary x1 + anyShowcase x3 + foilCommon x7 + foilRareMythic x1 + foilUncommon x2 + rmExtended x1 / w80: ancillary x1 + anyShowcase x3 + foilCommon x6 + foilRareMythic x1 + foilUncommon x3 + rmExtended x1 / w25: ancillary x1 + anyShowcase x3 + foilCommon x5 + foilRareMythic x1 + foilUncommon x4 + rmExtended x1 / w14: ancillary x1 + anyShowcase x3 + foilCommon x4 + foilRareMythic x1 + foilUncommon x5 + rmExtended x1 / w7: ancillary x1 + anyShowcase x3 + foilCommon x3 + foilRareMythic x1 +  |
| ELD | draft | draft/default | 4 | w52: basic x1 + common x10 + rareMythic x1 + uncommon x3 / w2: basic x1 + common x10 + rareMythicShowcase x1 + uncommon x3 / w26: basic x1 + common x9 + foil x1 + rareMythic x1 + uncommon x3 / w1: basic x1 + common x9 + foil x1 + rareMythicShowcase x1 + uncommon x3 |
| ELD | theme-b | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ELD | theme-g | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ELD | theme-r | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ELD | theme-u | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ELD | theme-w | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | collector | collector | 2 | w5: commonUncommonShowcase x2 + extendedRareMythic x1 + foilBasic x1 + foilCommon x5 + foilCommonUncommonShowcase x1 + foilRareMythic x1 + foilRareMythicShowcase x1 + foilUncommon x2 + rareMythicShowcase x1 / w1: commonUncommonShowcase x2 + extendedRareMythic x1 + foilBasic x1 + foilCommon x5 + foilCommonUncommonShowcase x1 + foilExpedition x1 + foilRareMythic x1 + foilUncommon x2 + rareMythicShowcase x1 |
| ZNR | draft | draft/default | 4 | w54: basic x1 + commonWithShowcase x10 + dfcRareMythicWithShowcase x1 + sfcUncommonWithShowcase x3 / w27: basic x1 + commonWithShowcase x9 + dfcRareMythicWithShowcase x1 + foilWithShowcase x1 + sfcUncommonWithShowcase x3 / w242: basic x1 + commonWithShowcase x10 + dfcUncommonWithShowcase x1 + sfcRareMythicWithShowcase x1 + sfcUncommonWithShowcase x2 / w121: basic x1 + commonWithShowcase x9 + dfcUncommonWithShowcase x1 + foilWithShowcase x1 + sfcRareMythicWithShowcase x1 + sfcUncommonWithShowcase |
| ZNR | set | set | 24 | w17850: basic x1 + common x5 + commonUncommonShowcase x1 + foilWithShowcase x1 + rareMythic x1 + uncommon x1 + wildcard x2 / w5950: basic x1 + common x5 + commonUncommonShowcase x1 + foilWithShowcase x1 + rareMythic x1 + theList x1 + uncommon x1 + wildcard x2 / w20400: basic x1 + common x4 + commonUncommonShowcase x1 + foilWithShowcase x1 + rareMythic x1 + uncommon x2 + wildcard x2 / w6800: basic x1 + common x4 + commonUncommonShowcase x1 + foilWithShowcase x1 + rareMythic x1 + theList x1 + unco |
| ZNR | theme-b | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | theme-g | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | theme-party | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | theme-r | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | theme-u | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| ZNR | theme-w | theme | 8 | w9: common x24 + rareMythic x1 + uncommon x10 / w1: common x24 + rareMythic x2 + uncommon x9 / w9: common x23 + rareMythic x1 + uncommon x11 / w1: common x23 + rareMythic x2 + uncommon x10 / w9: common x22 + rareMythic x1 + uncommon x12 / w1: common x22 + rareMythic x2 + uncommon x11 / w9: common x21 + rareMythic x1 + uncommon x13 / w1: common x21 + rareMythic x2 + uncommon x12 |
| STX | collector | collector | 2 | w1: etchedJpStaRareMythic x1 + etchedStaUncommon x1 + extendedCommander x1 + extendedOrBorderlessCore x1 + foilAltArtWild x1 + foilCommon x5 + foilLesson x1 + foilRareMythic x1 + foilStaUncommon x1 + foilUncommon x2 / w1: etchedJpStaUncommon x1 + etchedStaRareMythic x1 + extendedCommander x1 + extendedOrBorderlessCore x1 + foilAltArtWild x1 + foilCommon x5 + foilLesson x1 + foilRareMythic x1 + foilStaUncommon x1 + foilUncommon x2 |
| STX | draft | draft/default | 2 | w2: lesson x1 + nonlessonCommon x9 + nonlessonRareMythic x1 + sta x1 + uncommon x3 / w1: foilWithShowcase x1 + lesson x1 + nonlessonCommon x8 + nonlessonRareMythic x1 + sta x1 + uncommon x3 |
| STX | jp | draft/default | 2 | w2: lesson x1 + nonlessonCommon x9 + nonlessonRareMythic x1 + sta x1 + uncommon x3 / w1: foilWithShowcase x1 + lesson x1 + nonlessonCommon x8 + nonlessonRareMythic x1 + sta x1 + uncommon x3 |
| STX | set | set | 24 | w17850: basic x1 + common x5 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + uncommon x1 + wildcard x1 / w5950: basic x1 + common x5 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + theList x1 + uncommon x1 + wildcard x1 / w20400: basic x1 + common x4 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + uncommon x2 + wildcard x1 / w6800: basic x1 + common x4 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + theList x1 + uncommon x2 + wildcard x1 / w637 |
| STX | set-jp | set | 24 | w17850: basic x1 + common x5 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + uncommon x1 + wildcard x1 / w5950: basic x1 + common x5 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + theList x1 + uncommon x1 + wildcard x1 / w20400: basic x1 + common x4 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + uncommon x2 + wildcard x1 / w6800: basic x1 + common x4 + foilWithShowcase x1 + lesson x1 + rareMythic x1 + sta x1 + theList x1 + uncommon x2 + wildcard x1 / w637 |
| STX | theme-lorehold | theme | 4 | w1: common x24 + rareMythic x1 + uncommon x10 / w1: common x23 + rareMythic x1 + uncommon x11 / w1: common x22 + rareMythic x1 + uncommon x12 / w1: common x21 + rareMythic x1 + uncommon x13 |
| STX | theme-prismari | theme | 4 | w1: common x24 + rareMythic x1 + uncommon x10 / w1: common x23 + rareMythic x1 + uncommon x11 / w1: common x22 + rareMythic x1 + uncommon x12 / w1: common x21 + rareMythic x1 + uncommon x13 |
| STX | theme-quandrix | theme | 4 | w1: common x24 + rareMythic x1 + uncommon x10 / w1: common x23 + rareMythic x1 + uncommon x11 / w1: common x22 + rareMythic x1 + uncommon x12 / w1: common x21 + rareMythic x1 + uncommon x13 |
| STX | theme-silverquill | theme | 4 | w1: common x24 + rareMythic x1 + uncommon x10 / w1: common x23 + rareMythic x1 + uncommon x11 / w1: common x22 + rareMythic x1 + uncommon x12 / w1: common x21 + rareMythic x1 + uncommon x13 |
| STX | theme-witherbloom | theme | 4 | w1: common x24 + rareMythic x1 + uncommon x10 / w1: common x23 + rareMythic x1 + uncommon x11 / w1: common x22 + rareMythic x1 + uncommon x12 / w1: common x21 + rareMythic x1 + uncommon x13 |
| CLB | collector | collector | 1 | w1: etchedCommonUncommon x1 + etchedRareMythic x1 + extendedCommander x1 + extendedRareMythic x1 + foilBasic x1 + foilCommon x3 + foilCommonUncommonLegendary x1 + foilCommonUncommonShowcase x1 + foilRareMythic x1 + foilShowcaseRareMythic x1 + foilUncommon x2 + rareMythicShowcase x1 |
| CLB | draft | draft/default | 2 | w5: background x1 + dedicatedFoil x1 + legendaryWithShowcase x1 + nonlegendaryCommonWithShowcase x13 + nonlegendaryRareMythicWithShowcase x1 + nonlegendaryUncommonWithShowcase x3 / w1: background x1 + dedicatedFoil x1 + legendaryWithShowcase x1 + nonlegendaryCommonWithShowcase x12 + nonlegendaryRareMythicWithShowcase x1 + nonlegendaryUncommonWithShowcase x3 + special x1 |
| CLB | set | set | 4 | w12: background x1 + basic x1 + common x3 + commonUncommonShowcase x1 + foilEtchedLegend x1 + foilWithShowcase x1 + legendaryWithShowcase x1 + rareMythic x1 + uncommon x3 + wildcard x2 / w4: background x1 + basic x1 + common x3 + commonUncommonShowcase x1 + foilEtchedLegend x1 + foilWithShowcase x1 + legendaryWithShowcase x1 + rareMythic x1 + theList x1 + uncommon x3 + wildcard x2 / w3: background x1 + common x3 + commonUncommonShowcase x1 + foilBasic x1 + foilEtchedLegend x1 + foilWithShowcase  |
| MKM | collector | collector | 2 | w183: commonUncommonShowcase x1 + extendedCommanderRareMythic x1 + extendedMainRareMythic x1 + foilCommon x4 + foilCommonUncommonShowcase x1 + foilFullartBasic x1 + foilRareMythic x1 + foilRareMythicShowcase x1 + foilUncommon x3 + rareMythicShowcase x1 / w17: commonUncommonShowcase x1 + extendedMainRareMythic x1 + foilCommon x4 + foilCommonUncommonShowcase x1 + foilExtendedCommanderRareMythic x1 + foilFullartBasic x1 + foilRareMythic x1 + foilRareMythicShowcase x1 + foilUncommon x3 + rareMythicS |
| MKM | play | play | 4 | w28: basic x1 + commonWithShowcase x7 + foil x1 + rareMythicWithShowcase x1 + uncommonWithShowcase x3 + wildcard x1 / w4: basic x1 + commonWithShowcase x6 + foil x1 + rareMythicWithShowcase x1 + theList x1 + uncommonWithShowcase x3 + wildcard x1 / w7: commonWithShowcase x7 + foil x1 + foilBasic x1 + rareMythicWithShowcase x1 + uncommonWithShowcase x3 + wildcard x1 / w1: commonWithShowcase x6 + foil x1 + foilBasic x1 + rareMythicWithShowcase x1 + theList x1 + uncommonWithShowcase x3 + wildcard x1 |
| FIN | collector | collector | 4 | w753571: boosterfunCommonUncommon x1 + foilBasic x1 + foilBoosterfunCommonUncommon x1 + foilBoosterfunRareMythic x1 + foilCommon x3 + foilRareMythic x1 + foilUncommon x3 + nonFoilBoosterfunRareMythic x3 + nonFoilThroughTheAges x1 / w753571: boosterfunCommonUncommon x1 + foilBasic x1 + foilBoosterfunCommonUncommon x1 + foilBoosterfunRareMythic x1 + foilCommon x3 + foilRareMythic x1 + foilThroughTheAges x1 + foilUncommon x3 + nonFoilBoosterfunRareMythic x3 / w246429: boosterfunCommonUncommon x1 +  |
| FIN | play | play | 4 | w8: common x7 + foil x1 + nonFoilLand x1 + rareMythic x1 + uncommon x3 + wildcard x1 / w2: common x7 + foil x1 + foilLand x1 + rareMythic x1 + uncommon x3 + wildcard x1 / w4: common x6 + foil x1 + nonFoilLand x1 + rareMythic x1 + throughTheAges x1 + uncommon x3 + wildcard x1 / w1: common x6 + foil x1 + foilLand x1 + rareMythic x1 + throughTheAges x1 + uncommon x3 + wildcard x1 |
| MSH | collector | collector | 2 | w3: boosterfun x1 + boosterfunCommander x1 + foilBoosterfun x1 + foilCUScene x1 + foilCommon x3 + foilCommonCommander x2 + foilLand x1 + foilRareMythic x1 + foilUncommon x2 + foilUncommonCommander x1 + nonFoilSourceMaterial x1 / w1: boosterfun x1 + boosterfunCommander x1 + foilBoosterfun x1 + foilCUScene x1 + foilCommon x3 + foilCommonCommander x2 + foilLand x1 + foilRareMythic x1 + foilSourceMaterial x1 + foilUncommon x2 + foilUncommonCommander x1 |
| MSH | jumpstart | jumpstart | 51 | w1: agentsOfSHIELD x20 / w1: analyzed x20 / w1: animal x20 / w1: armed x20 / w1: atlantis x20 / w1: battalion x20 / w1: blink x20 / w1: boosted x20 / w1: caretakers x20 / w1: conniving x20 / w1: counterargument x20 / w1: doom x20 / w1: equipped x20 / w1: fantastic x20 / w1: fearless x20 / w1: geniuses x20 / w1: greatLakesAvengers x20 / w1: hydra x20 / w1: heroesForHire x20 / w1: incredible x20 / w1: ironMan x20 / w1: kangDynasty x20 / w1: lethal x20 / w1: marvelous x20 / w1: mastersOfEvil x20 /  |
| MSH | play | play | 4 | w92: common x7 + foil x1 + nonFoilLand x1 + rareMythic x1 + uncommon x3 + wildcard x1 / w23: common x7 + foil x1 + foilLand x1 + rareMythic x1 + uncommon x3 + wildcard x1 / w4: common x6 + foil x1 + nonFoilLand x1 + rareMythic x1 + sourceMaterial x1 + uncommon x3 + wildcard x1 / w1: common x6 + foil x1 + foilLand x1 + rareMythic x1 + sourceMaterial x1 + uncommon x3 + wildcard x1 |

## Complete Released Paper Set List

This is one row per released set with at least one paper MTGJSON booster config. Exact slot specs are in `mtg-booster-inventory.csv`.

| Date | Code | Set | Booster configs |
| --- | --- | --- | --- |
| 1993-08-05 | LEA | Limited Edition Alpha | default (draft/default), starter (starter/tournament) |
| 1993-10-04 | LEB | Limited Edition Beta | default (draft/default), starter (starter/tournament) |
| 1993-12-01 | 2ED | Unlimited Edition | default (draft/default), starter (starter/tournament) |
| 1993-12-17 | ARN | Arabian Nights | default (draft/default) |
| 1994-03-04 | ATQ | Antiquities | default (draft/default) |
| 1994-04-11 | 3ED | Revised Edition | default (draft/default), starter (starter/tournament) |
| 1994-06-01 | LEG | Legends | default (draft/default) |
| 1994-06-21 | SUM | Summer Magic / Edgar | default (draft/default) |
| 1994-08-01 | DRK | The Dark | default (draft/default) |
| 1994-11-01 | FEM | Fallen Empires | default (draft/default) |
| 1995-04-01 | 4ED | Fourth Edition | default (draft/default), starter (starter/tournament) |
| 1995-06-03 | ICE | Ice Age | default (draft/default), starter (starter/tournament) |
| 1995-07-01 | CHR | Chronicles | default (draft/default) |
| 1995-08-01 | REN | Renaissance | default (draft/default) |
| 1995-08-01 | RIN | Rinascimento | default (draft/default) |
| 1995-10-01 | HML | Homelands | default (draft/default) |
| 1996-06-10 | ALL | Alliances | default (draft/default) |
| 1996-10-08 | MIR | Mirage | draft (draft/default), starter (starter/tournament) |
| 1997-02-03 | VIS | Visions | draft (draft/default) |
| 1997-03-24 | 5ED | Fifth Edition | draft (draft/default), starter (starter/tournament) |
| 1997-05-01 | POR | Portal | default (draft/default) |
| 1997-06-09 | WTH | Weatherlight | draft (draft/default) |
| 1997-10-14 | TMP | Tempest | draft (draft/default), starter (starter/tournament) |
| 1998-03-02 | STH | Stronghold | draft (draft/default) |
| 1998-06-15 | EXO | Exodus | draft (draft/default) |
| 1998-06-24 | P02 | Portal Second Age | default (draft/default) |
| 1998-08-11 | UGL | Unglued | draft (draft/default) |
| 1998-10-12 | USG | Urza's Saga | draft (draft/default), tournament (starter/tournament) |
| 1999-02-15 | ULG | Urza's Legacy | draft (draft/default) |
| 1999-04-21 | 6ED | Classic Sixth Edition | draft (draft/default), tournament (starter/tournament) |
| 1999-05-01 | PTK | Portal Three Kingdoms | default (draft/default) |
| 1999-06-07 | UDS | Urza's Destiny | draft (draft/default) |
| 1999-07-01 | S99 | Starter 1999 | default (draft/default) |
| 1999-10-04 | MMQ | Mercadian Masques | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2000-02-14 | NEM | Nemesis | draft (draft/default), fat-pack (special/other) |
| 2000-06-05 | PCY | Prophecy | draft (draft/default), fat-pack (special/other) |
| 2000-10-02 | INV | Invasion | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2001-02-05 | PLS | Planeshift | draft (draft/default), fat-pack (special/other) |
| 2001-04-11 | 7ED | Seventh Edition | draft (draft/default) |
| 2001-06-04 | APC | Apocalypse | draft (draft/default), fat-pack (special/other) |
| 2001-10-01 | ODY | Odyssey | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2002-02-04 | TOR | Torment | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2002-05-27 | JUD | Judgment | draft (draft/default), fat-pack (special/other) |
| 2002-10-07 | ONS | Onslaught | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2003-02-03 | LGN | Legions | draft (draft/default), fat-pack (special/other) |
| 2003-05-26 | SCG | Scourge | draft (draft/default), fat-pack (special/other) |
| 2003-07-28 | 8ED | Eighth Edition | draft (draft/default) |
| 2003-10-02 | MRD | Mirrodin | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2004-02-06 | DST | Darksteel | draft (draft/default), fat-pack (special/other) |
| 2004-06-04 | 5DN | Fifth Dawn | draft (draft/default), fat-pack (special/other) |
| 2004-10-01 | CHK | Champions of Kamigawa | draft (draft/default), fat-pack (special/other), tournament (starter/tournament) |
| 2004-11-19 | UNH | Unhinged | draft (draft/default) |
| 2005-02-04 | BOK | Betrayers of Kamigawa | draft (draft/default), fat-pack (special/other) |
| 2005-06-03 | SOK | Saviors of Kamigawa | draft (draft/default), fat-pack (special/other) |
| 2005-07-29 | 9ED | Ninth Edition | draft (draft/default) |
| 2005-10-07 | RAV | Ravnica: City of Guilds | draft (draft/default), tournament (starter/tournament) |
| 2006-02-03 | GPT | Guildpact | draft (draft/default) |
| 2006-05-05 | DIS | Dissension | draft (draft/default) |
| 2006-07-21 | CSP | Coldsnap | draft (draft/default) |
| 2006-10-06 | TSP | Time Spiral | draft (draft/default) |
| 2007-02-02 | PLC | Planar Chaos | draft (draft/default) |
| 2007-05-04 | FUT | Future Sight | draft (draft/default) |
| 2007-07-13 | 10E | Tenth Edition | draft (draft/default) |
| 2007-10-12 | LRW | Lorwyn | draft (draft/default), tournament (starter/tournament) |
| 2008-02-01 | MOR | Morningtide | draft (draft/default) |
| 2008-05-02 | SHM | Shadowmoor | draft (draft/default), tournament (starter/tournament) |
| 2008-07-25 | EVE | Eventide | draft (draft/default) |
| 2008-10-03 | ALA | Shards of Alara | draft (draft/default), premium (special/other), tournament (starter/tournament) |
| 2009-02-06 | CON | Conflux | draft (draft/default), six (six-card/sample) |
| 2009-04-30 | ARB | Alara Reborn | draft (draft/default), six (six-card/sample) |
| 2009-07-17 | M10 | Magic 2010 | draft (draft/default), six (six-card/sample) |
| 2009-10-02 | ZEN | Zendikar | draft (draft/default), six (six-card/sample) |
| 2010-02-05 | WWK | Worldwake | draft (draft/default), six (six-card/sample) |
| 2010-04-23 | ROE | Rise of the Eldrazi | draft (draft/default), six (six-card/sample) |
| 2010-07-16 | M11 | Magic 2011 | draft (draft/default), six (six-card/sample) |
| 2010-10-01 | SOM | Scars of Mirrodin | draft (draft/default), six (six-card/sample) |
| 2011-02-04 | MBS | Mirrodin Besieged | draft (draft/default), six (six-card/sample) |
| 2011-05-13 | NPH | New Phyrexia | draft (draft/default), six (six-card/sample) |
| 2011-07-15 | M12 | Magic 2012 | draft (draft/default), six (six-card/sample) |
| 2011-09-30 | ISD | Innistrad | draft (draft/default), six (six-card/sample) |
| 2012-02-03 | DKA | Dark Ascension | draft (draft/default), six (six-card/sample) |
| 2012-05-04 | AVR | Avacyn Restored | draft (draft/default), six (six-card/sample) |
| 2012-07-13 | M13 | Magic 2013 | draft (draft/default), six (six-card/sample) |
| 2012-10-05 | RTR | Return to Ravnica | draft (draft/default), prerelease-azorius (prerelease/promo), prerelease-golgari (prerelease/promo), prerelease-izzet (prerelease/promo), prerelease-rakdos (prerelease/promo), prerelease-selesnya (prerelease/promo), six (six-card/sample) |
| 2013-02-01 | GTC | Gatecrash | draft (draft/default), prerelease-boros (prerelease/promo), prerelease-dimir (prerelease/promo), prerelease-gruul (prerelease/promo), prerelease-orzhov (prerelease/promo), prerelease-simic (prerelease/promo), six (six-card/sample) |
| 2013-05-03 | DGM | Dragon's Maze | draft (draft/default), six (six-card/sample) |
| 2013-06-07 | MMA | Modern Masters | draft (draft/default) |
| 2013-07-19 | M14 | Magic 2014 | draft (draft/default), duelspromo (promo/bundle/topper), six (six-card/sample) |
| 2013-09-27 | THS | Theros | draft (draft/default) |
| 2014-02-07 | BNG | Born of the Gods | draft (draft/default) |
| 2014-05-02 | JOU | Journey into Nyx | draft (draft/default) |
| 2014-06-06 | CNS | Conspiracy | draft (draft/default) |
| 2014-07-18 | M15 | Magic 2015 | draft (draft/default), duelspromo (promo/bundle/topper) |
| 2014-09-26 | KTK | Khans of Tarkir | draft (draft/default), prerelease (prerelease/promo) |
| 2015-01-17 | UGIN | Ugin's Fate | fate (special/other) |
| 2015-01-23 | FRF | Fate Reforged | draft (draft/default), prerelease (prerelease/promo) |
| 2015-03-27 | DTK | Dragons of Tarkir | draft (draft/default), fat-pack (special/other), prerelease-atarka (prerelease/promo), prerelease-dromoka (prerelease/promo), prerelease-kolaghan (prerelease/promo), prerelease-ojutai (prerelease/promo), prerelease-silumgar (prerelease/promo) |
| 2015-05-22 | MM2 | Modern Masters 2015 | draft (draft/default) |
| 2015-07-17 | ORI | Magic Origins | draft (draft/default), prerelease (prerelease/promo) |
| 2015-10-02 | BFZ | Battle for Zendikar | draft (draft/default), prerelease (prerelease/promo) |
| 2016-01-22 | OGW | Oath of the Gatewatch | draft (draft/default), prerelease (prerelease/promo) |
| 2016-04-08 | SOI | Shadows over Innistrad | draft (draft/default), prerelease (prerelease/promo) |
| 2016-06-10 | EMA | Eternal Masters | draft (draft/default) |
| 2016-07-22 | EMN | Eldritch Moon | draft (draft/default), prerelease (prerelease/promo) |
| 2016-08-26 | CN2 | Conspiracy: Take the Crown | draft (draft/default) |
| 2016-09-30 | KLD | Kaladesh | draft (draft/default), prerelease (prerelease/promo) |
| 2017-01-20 | AER | Aether Revolt | draft (draft/default), prerelease (prerelease/promo) |
| 2017-03-17 | MM3 | Modern Masters 2017 | draft (draft/default) |
| 2017-04-28 | AKH | Amonkhet | draft (draft/default), prerelease (prerelease/promo) |
| 2017-07-14 | HOU | Hour of Devastation | draft (draft/default), prerelease (prerelease/promo) |
| 2017-09-29 | XLN | Ixalan | draft (draft/default), prerelease (prerelease/promo), treasure-chest (special/other) |
| 2017-11-17 | IMA | Iconic Masters | draft (draft/default) |
| 2017-12-08 | UST | Unstable | draft (draft/default) |
| 2018-01-19 | RIX | Rivals of Ixalan | draft (draft/default), prerelease (prerelease/promo) |
| 2018-03-16 | A25 | Masters 25 | draft (draft/default) |
| 2018-04-27 | DOM | Dominaria | draft (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2018-06-08 | BBD | Battlebond | draft (draft/default), prerelease (prerelease/promo) |
| 2018-06-15 | SS1 | Signature Spellbook: Jace | default (draft/default) |
| 2018-07-13 | M19 | Core Set 2019 | draft (draft/default), prerelease (prerelease/promo) |
| 2018-10-05 | GRN | Guilds of Ravnica | draft (draft/default), prerelease (prerelease/promo), theme-boros (theme), theme-dimir (theme), theme-golgari (theme), theme-izzet (theme), theme-selesnya (theme) |
| 2018-12-07 | UMA | Ultimate Masters | box-topper (promo/bundle/topper), draft (draft/default) |
| 2019-01-25 | RNA | Ravnica Allegiance | draft (draft/default), prerelease (prerelease/promo), theme-azorius (theme), theme-gruul (theme), theme-orzhov (theme), theme-rakdos (theme), theme-simic (theme) |
| 2019-05-03 | WAR | War of the Spark | draft (draft/default), jp (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2019-06-14 | MH1 | Modern Horizons | draft (draft/default) |
| 2019-06-28 | SS2 | Signature Spellbook: Gideon | default (draft/default) |
| 2019-07-12 | M20 | Core Set 2020 | draft (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2019-10-04 | ELD | Throne of Eldraine | collector (collector), draft (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2019-11-07 | MB1 | Mystery Booster | convention (special/other), convention-2021 (special/other), draft (draft/default) |
| 2019-12-02 | SLD | Secret Lair Drop | baseball-signed (special/other), blueprint-mk1 (special/other), blueprint-mk2 (special/other), chaos-emeralds (special/other), deceptive-districts (special/other), dnd-50th-anniversary (special/other), fin-elementals (special/other), spider-man (special/other), stainedglass-b (special/other), stainedglass-c (special/other), stainedglass-g (special/other), stainedglass-iwd (special/other), stainedglass-r (special/other), stainedglass-tattoo (special/other), stainedglass-u (special/other), stainedglass-uncommon (special/other), stainedglass-w (special/other) |
| 2020-01-24 | THB | Theros Beyond Death | collector (collector), draft (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2020-04-24 | IKO | Ikoria: Lair of Behemoths | box-topper (promo/bundle/topper), collector (collector), collector-jp (collector), draft (draft/default), jp (draft/default), prerelease (prerelease/promo), theme-b (theme), theme-g (theme), theme-monsters (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2020-06-26 | SS3 | Signature Spellbook: Chandra | default (draft/default) |
| 2020-07-03 | M21 | Core Set 2021 | collector (collector), draft (draft/default), prerelease (prerelease/promo) |
| 2020-07-17 | JMP | Jumpstart | jumpstart (jumpstart) |
| 2020-08-07 | 2XM | Double Masters | box-topper (promo/bundle/topper), draft (draft/default), vip (special/other) |
| 2020-09-25 | ZNE | Zendikar Rising Expeditions | box-topper (promo/bundle/topper) |
| 2020-09-25 | ZNR | Zendikar Rising | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-g (theme), theme-party (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2020-11-20 | CMR | Commander Legends | collector (collector), draft (draft/default) |
| 2021-02-05 | KHM | Kaldheim | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-vikings (theme), theme-w (theme) |
| 2021-03-19 | TSR | Time Spiral Remastered | draft (draft/default) |
| 2021-04-23 | STX | Strixhaven: School of Mages | collector (collector), draft (draft/default), jp (draft/default), prerelease (prerelease/promo), set (set), set-jp (set), theme-lorehold (theme), theme-prismari (theme), theme-quandrix (theme), theme-silverquill (theme), theme-witherbloom (theme) |
| 2021-06-18 | MH2 | Modern Horizons 2 | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set) |
| 2021-07-23 | AFR | Adventures in the Forgotten Realms | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-dungeons (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2021-09-24 | MID | Innistrad: Midnight Hunt | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-w (theme), theme-werewolves (theme) |
| 2021-11-19 | VOW | Innistrad: Crimson Vow | box-topper (promo/bundle/topper), collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-g (theme), theme-r (theme), theme-u (theme), theme-vampires (theme), theme-w (theme) |
| 2022-01-28 | DBL | Innistrad: Double Feature | draft (draft/default) |
| 2022-02-18 | NEO | Kamigawa: Neon Dynasty | collector (collector), draft (draft/default), prerelease (prerelease/promo), set (set), theme-b (theme), theme-g (theme), theme-ninjas (theme), theme-r (theme), theme-u (theme), theme-w (theme) |
| 2022-04-29 | SNC | Streets of New Capenna | collector (collector), collector-sample (collector-sample), draft (draft/default), prerelease-brokers (prerelease/promo), prerelease-cabaretti (prerelease/promo), prerelease-maestros (prerelease/promo), prerelease-obscura (prerelease/promo), prerelease-riveteers (prerelease/promo), set (set), theme-brokers (theme), theme-cabaretti (theme), theme-maestros (theme), theme-obscura (theme), theme-riveteers (theme) |
| 2022-06-10 | CLB | Commander Legends: Battle for Baldur's Gate | collector (collector), collector-sample (collector-sample), draft (draft/default), prerelease (prerelease/promo), set (set) |
| 2022-07-08 | 2X2 | Double Masters 2022 | collector (collector), draft (draft/default) |
| 2022-09-09 | DMU | Dominaria United | box-topper (promo/bundle/topper), collector (collector), collector-sample (collector-sample), draft (draft/default), jumpstart (jumpstart), prerelease (prerelease/promo), set (set) |
| 2022-10-07 | UNF | Unfinity | box-topper (promo/bundle/topper), collector (collector), draft (draft/default) |
| 2022-11-18 | BRO | The Brothers' War | collector (collector), collector-sample (collector-sample), draft (draft/default), jumpstart (jumpstart), prerelease (prerelease/promo), set (set) |
| 2022-11-28 | 30A | 30th Anniversary Edition | draft (draft/default) |
| 2022-12-02 | J22 | Jumpstart 2022 | jumpstart (jumpstart) |
| 2023-01-13 | DMR | Dominaria Remastered | collector (collector), draft (draft/default) |
| 2023-02-10 | ONE | Phyrexia: All Will Be One | collector (collector), collector-sample (collector-sample), compleat (special/other), draft (draft/default), jumpstart (jumpstart), prerelease (prerelease/promo), set (set) |
| 2023-04-21 | MOM | March of the Machine | collector (collector), collector-sample (collector-sample), draft (draft/default), jumpstart (jumpstart), prerelease (prerelease/promo), set (set) |
| 2023-05-12 | MAT | March of the Machine: The Aftermath | collector (collector), default (draft/default) |
| 2023-06-23 | LTR | The Lord of the Rings: Tales of Middle-earth | box-topper (promo/bundle/topper), collector (collector), collector-sample (collector-sample), collector-special (collector), draft (draft/default), jumpstart (jumpstart), jumpstart-v2 (jumpstart), prerelease (prerelease/promo), set (set) |
| 2023-08-04 | CMM | Commander Masters | collector (collector), collector-sample (collector-sample), draft (draft/default), set (set) |
| 2023-09-08 | WOE | Wilds of Eldraine | collector (collector), collector-sample (collector-sample), draft (draft/default), prerelease (prerelease/promo), set (set) |
| 2023-10-13 | WHO | Doctor Who | collector (collector), collector-sample (collector-sample) |
| 2023-11-17 | LCI | The Lost Caverns of Ixalan | box-topper (promo/bundle/topper), box-topper-foil (promo/bundle/topper), bundle-promo (promo/bundle/topper), collector (collector), collector-sample (collector-sample), draft (draft/default), gift-bundle-promo (promo/bundle/topper), prerelease (prerelease/promo), set (set) |
| 2024-01-12 | RVR | Ravnica Remastered | collector (collector), draft (draft/default) |
| 2024-02-09 | MKM | Murders at Karlov Manor | collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2024-02-23 | CLU | Ravnica: Clue Edition | box-topper (promo/bundle/topper), default (draft/default) |
| 2024-03-08 | PIP | Fallout | collector (collector), collector-sample (collector-sample) |
| 2024-04-19 | OTJ | Outlaws of Thunder Junction | collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2024-06-14 | MH3 | Modern Horizons 3 | collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2024-07-05 | ACR | Assassin's Creed | collector (collector), default (draft/default) |
| 2024-08-02 | BLB | Bloomburrow | collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2024-08-02 | MB2 | Mystery Booster 2 | draft (draft/default) |
| 2024-09-27 | DSK | Duskmourn: House of Horror | collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2024-11-15 | FDN | Foundations | beginner (special/other), collector (collector), play (play), prerelease (prerelease/promo) |
| 2024-11-15 | J25 | Foundations Jumpstart | jumpstart (jumpstart) |
| 2025-01-24 | INR | Innistrad Remastered | collector (collector), play (play) |
| 2025-02-14 | DFT | Aetherdrift | box-topper (promo/bundle/topper), collector (collector), play (play), prerelease (prerelease/promo) |
| 2025-04-11 | TDM | Tarkir: Dragonstorm | collector (collector), play (play), prerelease (prerelease/promo) |
| 2025-06-13 | FIN | Final Fantasy | bundle-promo (promo/bundle/topper), chocobo-bundle (promo/bundle/topper), chocobo-bundle-scene (promo/bundle/topper), collector (collector), collector-sample (collector-sample), play (play), prerelease (prerelease/promo) |
| 2025-08-01 | EOE | Edge of Eternities | collector (collector), play (play), prerelease (prerelease/promo) |
| 2025-09-26 | SPM | Marvel's Spider-Man | collector (collector), play (play), prerelease (prerelease/promo) |
| 2025-11-21 | TLA | Avatar: The Last Airbender | collector (collector), play (play), prerelease (prerelease/promo) |
| 2025-11-21 | TLE | Avatar: The Last Airbender Eternal | jumpstart (jumpstart) |
| 2026-01-23 | ECL | Lorwyn Eclipsed | collector (collector), play (play) |
| 2026-03-06 | TMT | Teenage Mutant Ninja Turtles | collector (collector), play (play) |
| 2026-04-24 | SOS | Secrets of Strixhaven | collector (collector), play (play) |
| 2026-06-26 | MSH | Marvel Super Heroes | collector (collector), jumpstart (jumpstart), play (play) |
