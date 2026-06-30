# MKM Fast Cache Prototype

Generated from Scryfall `set:mkm`.

## Files

- `mkm_play_fast_cache.lua`: standalone Lua prototype with compact MKM card data and local Play Booster slot selection.

## Why This Test

The current generator warms many Scryfall search caches for a set. For MKM, the current `default14CardPack` warm shape can expand to about 36 query caches over repeated packs. The prototype loads the set card pool once, builds local slot pools, and then generates packs without additional per-slot search caches.

## Compact Fixture

- Cards loaded: 440
- Compact JSON payload size: 102,098 bytes
- Generated Lua fixture size: 154,635 bytes
- Pool counts: {'land': 15, 'common': 92, 'uncommon': 125, 'rareMythic': 208, 'wildcard': 425, 'foil': 425}

## Measured Current Cache Shape

Fetching the current-style MKM warm-cache queries produced:

- Query caches: 36
- Cached card records across those query caches: 716
- Unique card names represented: 279
- Estimated current compact-cache JSON size: 788,517 bytes

That compares with the prototype's one compact set pool of 440 records / 102,098 JSON bytes. The current approach repeats cards across color and rarity buckets; the prototype stores each print once, then builds local buckets in Lua.

## Current Warm Query Shape For MKM

- `set:MKM+r:common+-t:basic+c:c+-t:creature`
- `set:MKM+r:common+-t:basic+c:c+t:creature`
- `set:MKM+r:common+-t:basic+c>=b`
- `set:MKM+r:common+-t:basic+c>=g`
- `set:MKM+r:common+-t:basic+c>=r`
- `set:MKM+r:common+-t:basic+c>=u`
- `set:MKM+r:common+-t:basic+c>=w`
- `set:MKM+r:common+c:c+-t:creature`
- `set:MKM+r:common+c:c+t:creature`
- `set:MKM+r:common+c>=b`
- `set:MKM+r:common+c>=g`
- `set:MKM+r:common+c>=r`
- `set:MKM+r:common+c>=u`
- `set:MKM+r:common+c>=w`
- `set:MKM+r:m+c:c+-t:creature`
- `set:MKM+r:m+c:c+t:creature`
- `set:MKM+r:m+c>=b`
- `set:MKM+r:m+c>=g`
- `set:MKM+r:m+c>=r`
- `set:MKM+r:m+c>=u`
- `set:MKM+r:m+c>=w`
- `set:MKM+r:r+c:c+-t:creature`
- `set:MKM+r:r+c:c+t:creature`
- `set:MKM+r:r+c>=b`
- `set:MKM+r:r+c>=g`
- `set:MKM+r:r+c>=r`
- `set:MKM+r:r+c>=u`
- `set:MKM+r:r+c>=w`
- `set:MKM+r:u+c:c+-t:creature`
- `set:MKM+r:u+c:c+t:creature`
- `set:MKM+r:u+c>=b`
- `set:MKM+r:u+c>=g`
- `set:MKM+r:u+c>=r`
- `set:MKM+r:u+c>=u`
- `set:MKM+r:u+c>=w`
- `set:MKM+t:basic+unique:prints`

## Prototype Caveats

- This is not production code.
- The List slot is mapped to the wildcard pool as a placeholder.
- Foil slots use the same card records with a slot label; this tests cache shape and local selection, not visual foil treatment.
- Exact MTGJSON sheet membership is not yet used. This prototype tests the speed idea first: one compact pool load, local buckets, then random picks.
