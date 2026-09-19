#!/usr/bin/env python3
"""Universal Folder Sorter — Python edition.

Sorts the files in a folder into subfolders by file type.
Folders are created only when needed, existing files are never
overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).

Usage: python3 sorter.py [folder] [options]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

VERSION = "2.0.0"

# category -> extensions (matched case-insensitively)
CATEGORIES: dict[str, list[str]] = {
    "Music": ["mp3", "wav", "ogg", "flac", "m4a", "wma", "aac", "opus", "mid", "midi"],
    "Image": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "svg", "ico", "tiff", "tif", "heic", "avif"],
    "Video": ["mp4", "mkv", "avi", "mov", "flv", "wmv", "webm", "m4v"],
    "Pdf": ["pdf"],
    "Office": ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "odt", "ods", "odp"],
    "Text": ["txt", "log", "md", "csv", "tsv", "json", "xml", "yaml", "yml", "ini", "conf"],
    "Code": ["py", "js", "ts", "html", "css", "c", "cpp", "h", "cs", "go", "rs", "java", "rb", "php", "sh", "bash", "ps1", "sql"],
    "Archives": ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"],
    "Fonts": ["ttf", "otf", "woff", "woff2"],
    "Executables": ["exe", "msi", "jar", "apk", "xapk", "deb", "rpm", "appimage", "bat", "cmd"],
    "Iso": ["iso", "img", "vhd", "vmdk"],
}

EXT_TO_CATEGORY: dict[str, str] = {
    ext: name for name, exts in CATEGORIES.items() for ext in exts
}


def default_folder() -> Path:
    for candidate in (Path.home() / "storage" / "downloads", Path.home() / "Downloads"):
        if candidate.is_dir():
            return candidate
    return Path.home() / "Downloads"


def resolve_dest(dest_dir: Path, name: str) -> Path:
    """Return a destination path inside dest_dir that doesn't exist yet."""
    dest = dest_dir / name
    if not dest.exists():
        return dest
    stem, dot, ext = name.rpartition(".")
    if not dot:
        stem, dot, ext = name, "", ""
    n = 1
    while True:
        candidate = dest_dir / f"{stem}_{n}{dot}{ext}"
        if not candidate.exists():
            return candidate
        n += 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="sorter.py",
        description="Sorts files in a folder into subfolders by file type. "
                    "Folders are created only when needed and existing files "
                    "are never overwritten (clashes become name_1.ext, ...).",
        epilog="If FOLDER is omitted, ~/storage/downloads is used when it "
               "exists, otherwise ~/Downloads.",
    )
    parser.add_argument("folder", nargs="?", default=None,
                        help="folder to sort (default: your downloads folder)")
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="show what would be moved without moving anything")
    parser.add_argument("-l", "--list", action="store_true",
                        help="print the category -> extension mapping and exit")
    parser.add_argument("-v", "--version", action="version",
                        version=f"Universal Folder Sorter v{VERSION} (Python)")
    args = parser.parse_args(argv)

    if args.list:
        print(f"Universal Folder Sorter v{VERSION} (Python) — categories:")
        for name, exts in CATEGORIES.items():
            print(f"  {name:<12} : {' '.join(exts)}")
        return 0

    target = Path(args.folder).expanduser() if args.folder else default_folder()
    if not target.is_dir():
        print(f"Error: folder not found: {target}", file=sys.stderr)
        return 1

    moved = 0
    unchanged = 0
    touched: list[str] = []

    for path in sorted(target.iterdir()):
        if not path.is_file():
            continue  # skip subfolders, hidden files, etc.
        name = path.name
        ext = path.suffix.lstrip(".").lower()
        category = EXT_TO_CATEGORY.get(ext) if ext else None
        if category is None:
            unchanged += 1
            continue

        dest_dir = target / category
        if args.dry_run:
            print(f"[dry-run] {name} -> {category}/")
        else:
            dest_dir.mkdir(exist_ok=True)
            path.rename(resolve_dest(dest_dir, name))
            print(f"Sorted: {name} -> {category}/")
        moved += 1
        if category not in touched:
            touched.append(category)

    where = f" into: {', '.join(touched)}" if touched else ""
    if args.dry_run:
        print()
        print(f"[dry-run] Would sort {moved} file(s){where}. "
              f"{unchanged} file(s) left unchanged. Nothing was moved.")
    else:
        print()
        print(f"Sorted {moved} file(s){where}. {unchanged} file(s) left unchanged.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
