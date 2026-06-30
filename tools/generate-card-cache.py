#!/usr/bin/env python3
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
USER_AGENT = "tabletop-simulator-mtg-booster-generator-card-cache/0.1"
DEFAULT_CHUNK_SIZE = 50


def fetch_json(url):
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def fetch_set_cards(set_code):
    cards = []
    query = "set:" + set_code.lower()
    url = "https://api.scryfall.com/cards/search?order=set&unique=prints&q=" + urllib.parse.quote(query)
    while url:
        page = fetch_json(url)
        cards.extend(page.get("data", []))
        url = page.get("next_page") if page.get("has_more") else None
    return cards


def fetch_scryfall_collection(scryfall_ids):
    cards = []
    for index in range(0, len(scryfall_ids), 75):
        identifiers = [{"id": card_id} for card_id in scryfall_ids[index:index + 75]]
        body = json.dumps({"identifiers": identifiers}).encode("utf-8")
        request = urllib.request.Request(
            "https://api.scryfall.com/cards/collection",
            data=body,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            page = json.load(response)
        cards.extend(page.get("data", []))
        if page.get("not_found"):
            missing = ", ".join(item.get("id", "?") for item in page["not_found"])
            raise RuntimeError("Scryfall collection lookup failed for: " + missing)
    return cards


def fetch_mtgjson_set(set_code):
    url = "https://mtgjson.com/api/v5/" + set_code.upper() + ".json"
    return fetch_json(url)["data"]


def compact_face(face):
    return {
        key: face[key]
        for key in (
            "name",
            "type_line",
            "cmc",
            "oracle_text",
            "power",
            "toughness",
            "loyalty",
            "image_uris",
        )
        if key in face and face[key] is not None
    }


def compact_card(card):
    compact = {
        key: card[key]
        for key in (
            "name",
            "type_line",
            "cmc",
            "oracle_text",
            "power",
            "toughness",
            "loyalty",
            "oracle_id",
            "image_uris",
            "rarity",
        )
        if key in card and card[key] is not None
    }
    if card.get("card_faces"):
        compact["card_faces"] = [compact_face(face) for face in card["card_faces"]]
    return compact


def main():
    set_code = (sys.argv[1] if len(sys.argv) > 1 else "mkm").lower()
    chunk_size = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_CHUNK_SIZE
    mtgjson_set = fetch_mtgjson_set(set_code)
    play_booster = mtgjson_set["booster"]["play"]
    uuid_to_mtgjson_card = {card["uuid"]: card for card in mtgjson_set["cards"]}

    card_ids = []
    seen_ids = set()
    sheets = {}
    for sheet_name, sheet in play_booster["sheets"].items():
        entries = []
        for uuid, weight in sheet["cards"].items():
            mtgjson_card = uuid_to_mtgjson_card.get(uuid)
            if not mtgjson_card:
                continue
            scryfall_id = mtgjson_card["identifiers"].get("scryfallId")
            if not scryfall_id:
                continue
            entries.append({"id": scryfall_id, "weight": weight})
            if scryfall_id not in seen_ids:
                seen_ids.add(scryfall_id)
                card_ids.append(scryfall_id)
        sheets[sheet_name] = {
            "foil": bool(sheet.get("foil")),
            "totalWeight": sheet.get("totalWeight"),
            "cards": entries,
        }

    missing_uuids = []
    for sheet in play_booster["sheets"].values():
        for uuid in sheet["cards"]:
            if uuid not in uuid_to_mtgjson_card:
                missing_uuids.append(uuid)
    if missing_uuids:
        for source_code in play_booster.get("sourceSetCodes", []):
            if source_code.upper() == set_code.upper():
                continue
            source_set = fetch_mtgjson_set(source_code)
            for card in source_set["cards"]:
                if card["uuid"] in missing_uuids:
                    uuid_to_mtgjson_card[card["uuid"]] = card

        for sheet_name, sheet in play_booster["sheets"].items():
            entries_by_id = {entry["id"]: entry for entry in sheets[sheet_name]["cards"]}
            for uuid, weight in sheet["cards"].items():
                mtgjson_card = uuid_to_mtgjson_card.get(uuid)
                if not mtgjson_card:
                    continue
                scryfall_id = mtgjson_card["identifiers"].get("scryfallId")
                if not scryfall_id or scryfall_id in entries_by_id:
                    continue
                sheets[sheet_name]["cards"].append({"id": scryfall_id, "weight": weight})
                if scryfall_id not in seen_ids:
                    seen_ids.add(scryfall_id)
                    card_ids.append(scryfall_id)

    unresolved_uuids = [
        uuid
        for sheet in play_booster["sheets"].values()
        for uuid in sheet["cards"]
        if uuid not in uuid_to_mtgjson_card
    ]
    if unresolved_uuids:
        raise RuntimeError("Could not resolve MTGJSON UUIDs: " + ", ".join(unresolved_uuids[:10]))

    scryfall_cards = fetch_scryfall_collection(card_ids)
    scryfall_by_id = {card["id"]: compact_card(card) for card in scryfall_cards}
    cards = {card_id: scryfall_by_id[card_id] for card_id in card_ids if card_id in scryfall_by_id}
    output_dir = ROOT / "assets" / "card-caches" / set_code
    output_dir.mkdir(parents=True, exist_ok=True)
    for old_cache in output_dir.glob("*.json"):
        old_cache.unlink()

    written = []
    card_items = list(cards.items())
    for index in range(0, len(card_items), chunk_size):
        chunk = dict(card_items[index:index + chunk_size])
        output_path = output_dir / f"{len(written) + 1:03}.json"
        payload = {
            "source": "scryfall",
            "boosterSource": "mtgjson",
            "set": set_code.upper(),
            "part": len(written) + 1,
            "cards": chunk,
        }
        output_path.write_text(json.dumps(payload, separators=(",", ":"), ensure_ascii=True), encoding="utf-8")
        written.append(output_path)

    for sheet_name, sheet in sheets.items():
        output_path = output_dir / f"{len(written) + 1:03}.json"
        payload = {
            "source": "mtgjson",
            "set": set_code.upper(),
            "part": len(written) + 1,
            "booster": "play",
            "sheets": {
                sheet_name: sheet,
            },
        }
        output_path.write_text(json.dumps(payload, separators=(",", ":"), ensure_ascii=True), encoding="utf-8")
        written.append(output_path)

    total_bytes = sum(path.stat().st_size for path in written)
    print(f"Wrote {len(written)} chunks to {output_dir} ({len(cards)} cards, {len(sheets)} sheets, {total_bytes} bytes)")
    for path in written:
        print(f"- {path.name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
