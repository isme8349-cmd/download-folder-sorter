#!/usr/bin/env bash
#
# Universal Folder Sorter — Bash edition
# Sorts the files in a folder into subfolders by file type.
# Folders are created only when needed, existing files are never
# overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).
#
# Usage: ./sorter.sh [folder] [options]

set -u

VERSION="2.0.0"
DRY_RUN=0
TARGET=""

# category:space-separated extensions (case-insensitive)
CATEGORIES=(
  "Music:mp3 wav ogg flac m4a wma aac opus mid midi"
  "Image:jpg jpeg png webp gif bmp svg ico tiff tif heic avif"
  "Video:mp4 mkv avi mov flv wmv webm m4v"
  "Pdf:pdf"
  "Office:doc docx xls xlsx ppt pptx rtf odt ods odp"
  "Text:txt log md csv tsv json xml yaml yml ini conf"
  "Code:py js ts html css c cpp h cs go rs java rb php sh bash ps1 sql"
  "Archives:zip rar 7z tar gz bz2 xz"
  "Fonts:ttf otf woff woff2"
  "Executables:exe msi jar apk xapk deb rpm appimage bat cmd"
  "Iso:iso img vhd vmdk"
)

usage() {
  cat <<EOF
Universal Folder Sorter v$VERSION (Bash)

Sorts files in a folder into subfolders by file type.
Folders are created only when needed, and existing files are never
overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).

Usage:
  ./sorter.sh [folder] [options]

Arguments:
  folder         Folder to sort. Default: ~/storage/downloads when it
                 exists, otherwise ~/Downloads.

Options:
  -n, --dry-run  Show what would be moved without moving anything.
  -l, --list     Print the category -> extension mapping and exit.
  -h, --help     Show this help and exit.
  -v, --version  Print the version and exit.

Examples:
  ./sorter.sh
  ./sorter.sh ~/Downloads
  ./sorter.sh ~/Downloads --dry-run
EOF
}

list_categories() {
  echo "Universal Folder Sorter v$VERSION (Bash) — categories:"
  for cat in "${CATEGORIES[@]}"; do
    printf '  %-12s : %s\n' "${cat%%:*}" "${cat#*:}"
  done
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    -v|--version) echo "Universal Folder Sorter v$VERSION (Bash)"; exit 0 ;;
    -l|--list)    list_categories; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -*)
      printf 'Error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$TARGET" ]; then
        printf 'Error: only one folder argument is allowed.\n' >&2
        exit 2
      fi
      TARGET="$1"
      ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  if [ -d "$HOME/storage/downloads" ]; then
    TARGET="$HOME/storage/downloads"
  else
    TARGET="$HOME/Downloads"
  fi
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: folder not found: %s\n' "$TARGET" >&2
  exit 1
fi

moved=0
unchanged=0
touched=""

for file in "$TARGET"/*; do
  [ -f "$file" ] || continue   # skip subfolders, hidden files, etc.
  base="${file##*/}"

  case "$base" in
    .*) unchanged=$((unchanged + 1)); continue ;;  # hidden file
  esac

  ext="${base##*.}"
  if [ "$ext" = "$base" ]; then
    unchanged=$((unchanged + 1))
    continue
  fi
  ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  category=""
  for cat in "${CATEGORIES[@]}"; do
    for e in ${cat#*:}; do
      if [ "$e" = "$ext_lc" ]; then
        category="${cat%%:*}"
        break 2
      fi
    done
  done

  if [ -z "$category" ]; then
    unchanged=$((unchanged + 1))
    continue
  fi

  # resolve a destination that never overwrites an existing file
  dest_dir="$TARGET/$category"
  stem="${base%.*}"
  dot_ext=".${base##*.}"
  dest="$dest_dir/$base"
  n=0
  while [ -e "$dest" ] || [ -L "$dest" ]; do
    n=$((n + 1))
    dest="$dest_dir/${stem}_$n$dot_ext"
  done

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s -> %s/\n' "$base" "$category"
  else
    mkdir -p "$dest_dir"
    mv -- "$file" "$dest"
    printf 'Sorted: %s -> %s/\n' "$base" "$category"
  fi

  moved=$((moved + 1))
  case " $touched " in
    *" $category "*) ;;
    *) touched="$touched $category" ;;
  esac
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  printf '[dry-run] Would sort %d file(s)%s. %d file(s) left unchanged. Nothing was moved.\n' \
    "$moved" \
    "$( [ -n "${touched# }" ] && printf ' into: %s' "${touched# }" )" \
    "$unchanged"
else
  printf 'Sorted %d file(s)%s. %d file(s) left unchanged.\n' \
    "$moved" \
    "$( [ -n "${touched# }" ] && printf ' into: %s' "${touched# }" )" \
    "$unchanged"
fi
