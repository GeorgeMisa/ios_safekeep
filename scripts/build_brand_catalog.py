"""Builds BrandCatalog.json and the BrandIcons asset sets from an unpacked simple-icons package.

Reads only the package's JSON data and SVG files; no package code is executed.
A full-color logo in scripts/brand-logos/<slug>.svg replaces the one-color glyph for that brand.
Usage: python3 -I scripts/build_brand_catalog.py <unpacked-package-dir> <brands.tsv> <resources-dir> <brand-logos-dir>
"""

import csv
import json
import re
import shutil
import sys
import unicodedata
from pathlib import Path

REPLACEMENTS = {"+": "plus", ".": "dot", "&": "and", "đ": "d", "ħ": "h", "ı": "i", "ĸ": "k", "ŀ": "l", "ł": "l", "ß": "ss", "ŧ": "t"}


def title_to_slug(title):
    slug = title.lower()
    for source, target in REPLACEMENTS.items():
        slug = slug.replace(source, target)
    slug = unicodedata.normalize("NFD", slug)
    return re.sub(r"[^a-z0-9]", "", slug)


def catalog_entry(slug, entry, row, has_glyph, full_color=False):
    return {
        "id": slug,
        "name": entry["title"],
        "hex": entry["hex"].upper(),
        "category": row["category"],
        "keywords": [word for word in (row.get("keywords") or "").split(",") if word],
        "website": row.get("website") or None,
        "hasGlyph": has_glyph,
        "fullColor": full_color,
    }


def write_imageset(assets, slug, source, rendering):
    imageset = assets / f"{slug}.imageset"
    imageset.mkdir(parents=True)
    shutil.copyfile(source, imageset / f"{slug}.svg")
    (imageset / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{slug}.svg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True, "template-rendering-intent": rendering},
    }, indent=2) + "\n", encoding="utf-8")


def load_entries(package):
    for candidate in ("data/simple-icons.json", "_data/simple-icons.json"):
        path = package / candidate
        if path.exists():
            data = json.loads(path.read_text(encoding="utf-8"))
            return data["icons"] if isinstance(data, dict) else data
    sys.exit("simple-icons data file not found")


def main():
    package, brands_file, resources, logos = (Path(arg) for arg in sys.argv[1:5])
    entries = {entry.get("slug") or title_to_slug(entry["title"]): entry for entry in load_entries(package)}

    assets = resources / "Assets.xcassets" / "BrandIcons"
    for child in assets.glob("*.imageset"):
        shutil.rmtree(child)

    catalog, missing = [], []
    with brands_file.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            slug = row["slug"]
            svg = package / "icons" / f"{slug}.svg"
            entry = entries.get(slug)
            fallback_entry = dict(zip(("title", "hex"), (row.get("fallback") or "").split("|")))
            color_logo = logos / f"{slug}.svg"
            if color_logo.exists() and (entry or len(fallback_entry) == 2):
                write_imageset(assets, slug, color_logo, "original")
                catalog.append(catalog_entry(slug, entry or fallback_entry, row, has_glyph=True, full_color=True))
                continue
            if entry is None or not svg.exists():
                fallback = (row.get("fallback") or "").split("|")
                if len(fallback) != 2:
                    missing.append(slug)
                    continue
                entry = {"title": fallback[0], "hex": fallback[1]}
                catalog.append(catalog_entry(slug, entry, row, has_glyph=False))
                continue

            write_imageset(assets, slug, svg, "template")
            catalog.append(catalog_entry(slug, entry, row, has_glyph=True))

    (resources / "BrandCatalog.json").write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Catalog has {len(catalog)} brands ({sum(b['hasGlyph'] for b in catalog)} with logos, {sum(b['fullColor'] for b in catalog)} full-color).")
    if missing:
        print("Skipped (not in this simple-icons release and no fallback): " + ", ".join(missing))


if __name__ == "__main__":
    main()
