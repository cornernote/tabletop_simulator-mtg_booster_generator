#!/usr/bin/env python3
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "src" / "fast_booster_specs.lua"
CACHE_ROOT = ROOT / "assets" / "card-caches"


def iter_fast_specs(source):
    entries = list(re.finditer(r"^    ([A-Z0-9]+)\s*=\s*{", source, re.MULTILINE))
    for index, match in enumerate(entries):
        code = match.group(1)
        end = entries[index + 1].start() if index + 1 < len(entries) else source.find("\n}", match.end())
        yield code, source[match.start():end]


def parse_spec(code, block):
    base_match = re.search(r'cardCacheBaseUrl\s*=\s*"([^"]+)"', block)
    parts_match = re.search(r"cardCacheParts\s*=\s*(\d+)", block)
    if not base_match and not parts_match:
        return None
    if not base_match or not parts_match:
        raise ValueError(f"{code}: cardCacheBaseUrl and cardCacheParts must be defined together")

    base_url = base_match.group(1)
    path_match = re.search(r"/assets/card-caches/([^/]+)/?$", base_url)
    if not path_match:
        raise ValueError(f"{code}: cardCacheBaseUrl does not point at assets/card-caches/<name>/")

    return {
        "code": code,
        "cache_dir": path_match.group(1),
        "parts": int(parts_match.group(1)),
    }


def main():
    source = SPEC_PATH.read_text(encoding="utf-8")
    specs = []
    errors = []

    for code, block in iter_fast_specs(source):
        try:
            spec = parse_spec(code, block)
        except ValueError as error:
            errors.append(str(error))
            continue
        if spec:
            specs.append(spec)

    if not specs:
        errors.append("No fast booster specs with cardCacheBaseUrl/cardCacheParts were found.")

    for spec in specs:
        cache_dir = CACHE_ROOT / spec["cache_dir"]
        missing = [
            f"{index:03d}.json"
            for index in range(1, spec["parts"] + 1)
            if not (cache_dir / f"{index:03d}.json").is_file()
        ]
        if missing:
            errors.append(
                f"{spec['code']}: missing {len(missing)} cache chunk(s) in "
                f"{cache_dir.relative_to(ROOT)}: {', '.join(missing)}"
            )

    if errors:
        print("Fast cache validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Fast cache validation passed: {len(specs)} spec(s) checked.")
    for spec in specs:
        print(f"- {spec['code']}: {spec['parts']} chunk(s) in assets/card-caches/{spec['cache_dir']}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
