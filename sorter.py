"""Universal Folder Sorter — Python edition.

Sorts the files in a folder into subfolders by file type.
Folders are created only when needed, existing files are never
overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).

Usage: python3 sorter.py [folder] [options]

Options:
  -n, --dry-run   Show what would be moved without moving anything.
  -l, --list      Print the category -> extension mapping and exit.
  -v, --version   Show the program version and exit.
"""

from __future__ import annotations

import argparse
from sys import argv, exit, stderr
from pathlib import Path
from shutil import move

VERSION = "2.0.0"

# Home directory, used to locate the default downloads folder.
PATH = Path.home()

# category -> extensions (matched case-insensitively).
# To add a new file type, just append its extension to the right list,
# or create a new category entry. Duplicates are detected at startup.
CATEGORIES = {
    "Music": ["mp3", "wav", "ogg", "flac", "m4a", "wma", "aac", "opus", "mid", "midi"],
    "Image": [
        "jpg",
        "jpeg",
        "png",
        "webp",
        "gif",
        "bmp",
        "svg",
        "ico",
        "tiff",
        "tif",
        "heic",
        "avif",
    ],
    "Video": ["mp4", "mkv", "avi", "mov", "flv", "wmv", "webm", "m4v"],
    "Pdf": ["pdf"],
    "Office": ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "odt", "ods", "odp"],
    "Text": [
        "txt",
        "log",
        "md",
        "csv",
        "tsv",
        "json",
        "xml",
        "yaml",
        "yml",
        "ini",
        "conf",
    ],
    "Code": [
        "py",
        "js",
        "ts",
        "html",
        "css",
        "c",
        "cpp",
        "h",
        "cs",
        "go",
        "rs",
        "java",
        "rb",
        "php",
        "sh",
        "bash",
        "ps1",
        "sql",
    ],
    "Archives": ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"],
    "Fonts": ["ttf", "otf", "woff", "woff2"],
    "Executables": [
        "exe",
        "msi",
        "jar",
        "apk",
        "xapk",
        "deb",
        "rpm",
        "appimage",
        "bat",
        "cmd",
    ],
    "Iso": ["iso", "img", "vhd", "vmdk"],
}

# Build the extension -> category map, checking for duplicates.
# If the same extension appears in two categories, we fail loudly at
# import time instead of silently letting one category win.
EXT_TO_CATEGORY: dict[str, str] = {}
for name, exts in CATEGORIES.items():
    for ext in exts:
        if ext in EXT_TO_CATEGORY:
            raise ValueError(
                f"Duplicate extension '{ext}' in "
                f"'{EXT_TO_CATEGORY[ext]}' and '{name}'"
            )
        EXT_TO_CATEGORY[ext] = name

# Clean up the loop variables so they don't leak into the module namespace.
del name, exts, ext


def default_folder() -> Path:
    """Return the default downloads folder.

    Prefers ~/storage/downloads (used on some systems) and falls back
    to ~/Downloads. Raises FileNotFoundError if neither exists.
    """
    for candidate in (PATH / "storage" / "downloads", PATH / "Downloads"):
        if candidate.is_dir():
            return candidate
    raise FileNotFoundError(
        "No download folder found "
        f"({PATH / 'storage' / 'downloads'} or {PATH / 'Downloads'})"
    )


def resolve_dest(
    dest_dir: Path, name: str, reserved: set[str] | None = None
) -> Path | None:
    """Return a non-existing destination path inside dest_dir.

    Existing files are never overwritten: clashes are renamed to
    name_1.ext, name_2.ext, ... The optional `reserved` set holds names
    already claimed during this run (needed for accurate dry-runs).

    Returns None if the name has no extension and clashes (no safe
    rename scheme exists in that case).
    """
    # Allow callers to omit `reserved` (used only for dry-run accuracy).
    if reserved is None:
        reserved = set()

    dest = dest_dir / name

    # Fast path: the name is free both on disk and within this run.
    if not dest.exists() and name not in reserved:
        return dest

    # Split "stem.ext" so we can build "stem_1.ext", "stem_2.ext", ...
    stem, dot, ext = name.rpartition(".")
    if not dot:
        # No extension and a clash: no safe rename scheme.
        return None

    # Find the first free numbered variant.
    n = 1
    while True:
        candidate_name = f"{stem}_{n}.{ext}"
        candidate = dest_dir / candidate_name
        if not candidate.exists() and candidate_name not in reserved:
            return candidate
        n += 1


def main() -> int:
    # --- CLI setup ---------------------------------------------------
    parser = argparse.ArgumentParser(
        prog="sorter.py",
        description="Sorts files in a folder into subfolders by file type. "
        "Folders are created only when needed and existing files "
        "are never overwritten (clashes become name_1.ext, ...).",
        epilog="If FOLDER is omitted, ~/storage/downloads is used when it "
        "exists, otherwise ~/Downloads.",
    )
    parser.add_argument(
        "folder",
        nargs="?",
        default=None,
        help="folder to sort (default: your downloads folder)",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="show what would be moved without moving anything",
    )
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="print the category -> extension mapping and exit",
    )
    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"Universal Folder Sorter v{VERSION} (Python)",
    )
    args = parser.parse_args(argv)

    # --- --list short-circuit ---------------------------------------
    if args.list:
        print(f"Universal Folder Sorter v{VERSION} (Python) — categories:")
        for name, exts in CATEGORIES.items():
            print(f"  {name:<12} : {' '.join(exts)}")
        return 0

    # --- Resolve the target folder ----------------------------------
    try:
        target = Path(args.folder).expanduser() if args.folder else default_folder()
    except FileNotFoundError as e:
        print(f"Error: {e}", file=stderr)
        return 1
    if not target.is_dir():
        print(f"Error: folder not found: {target}", file=stderr)
        return 1

    # --- Counters and state -----------------------------------------
    moved = 0            # files moved (or that would be moved in dry-run)
    skipped_no_ext = 0   # extensionless files skipped due to a name clash
    unchanged = 0        # files whose extension is not in any category
    touched: list[str] = []        # categories actually used (for summary)
    reserved: set[str] = set()     # names claimed during this run

    # --- Main loop ---------------------------------------------------
    # Sort by lowercased name so behaviour is stable across platforms.
    for path in sorted(target.iterdir(), key=lambda p: p.name.lower()):
        # Only files are sorted; subfolders are left untouched.
        if not path.is_file():
            continue

        name = path.name
        ext = path.suffix.lstrip(".").lower()
        category = EXT_TO_CATEGORY.get(ext) if ext else None

        # Unknown extensions are left untouched.
        if category is None:
            unchanged += 1
            continue

        dest_dir = target / category

        # In a real run, create the destination folder only if needed.
        # In dry-run we skip mkdir so nothing is written to disk.
        if not args.dry_run:
            dest_dir.mkdir(parents=True, exist_ok=True)

        # Compute a free destination, honouring names reserved earlier
        # in this same run (important for accurate dry-run output).
        rd = resolve_dest(dest_dir, name, reserved)
        if rd is None:
            print(f"Skipped (no extension, name clash): {name}", file=stderr)
            skipped_no_ext += 1
            continue
        reserved.add(rd.name)

        # Dry-run: just log. Real run: actually move the file.
        if args.dry_run:
            print(f"[dry-run] {name} -> {category}/")
        else:
            move(str(path), str(rd))
            print(f"Sorted: {name} -> {category}/")

        moved += 1
        if category not in touched:
            touched.append(category)

    # --- Summary -----------------------------------------------------
    where = f" into: {', '.join(touched)}" if touched else ""

    if args.dry_run:
        print()
        print(
            f"[dry-run] Would sort {moved} file(s){where}. "
            f"{unchanged} file(s) left unchanged."
        )
        if skipped_no_ext:
            print(
                f"[dry-run] {skipped_no_ext} file(s) would be skipped "
                f"(no extension + name clash)."
            )
        print("[dry-run] Nothing was moved.")
    else:
        print()
        print(f"Sorted {moved} file(s){where}. {unchanged} file(s) left unchanged.")
        if skipped_no_ext:
            print(
                f"Skipped {skipped_no_ext} file(s) without extension "
                f"due to name clash."
            )

    return 0


if __name__ == "__main__":
    exit(main())
