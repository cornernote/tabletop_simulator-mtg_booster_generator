#!/usr/bin/env python3
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
USER_AGENT = "tabletop-simulator-mtg-booster-generator-card-cache/0.1"


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
    cards = [compact_card(card) for card in fetch_set_cards(set_code)]
    output_dir = ROOT / "assets" / "card-caches"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{set_code}.json"
    payload = {
        "source": "scryfall",
        "set": set_code.upper(),
        "cards": cards,
    }
    output_path.write_text(json.dumps(payload, separators=(",", ":"), ensure_ascii=True), encoding="utf-8")
    print(f"Wrote {output_path} ({len(cards)} cards, {output_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
