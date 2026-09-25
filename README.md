# 📂 Download Folder Sorter

> One small script, five languages, zero clutter. Sorts any folder into tidy
> type-based subfolders — **Music, Image, Video, Code, …** — without ever
> overwriting a single file.

[![version](https://img.shields.io/badge/version-2.0.0-blue)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)
[![platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%2C%20Windows%2C%20Android-blueviolet)](#supported-platforms)
[![python](https://img.shields.io/badge/python-3.7%2B-yellow)](https://www.python.org)
[![php](https://img.shields.io/badge/php-7.1%2B-8892BF)](https://www.php.net)

| Language | Script | Platform |
|----------|--------|----------|
| 🐚 Bash | [`sorter.sh`](sorter.sh) | Linux · macOS · Android (Termux) · WSL |
| 🐍 Python | [`sorter.py`](sorter.py) | anywhere Python 3.7+ runs |
| 💾 CMD | [`sorter.bat`](sorter.bat) | Windows (double-click or from a terminal) |
| 🪟 PowerShell | [`sorter.ps1`](sorter.ps1) | Windows PowerShell 5.1+ / PowerShell 7+ |
| 🐘 PHP | [`sorter.php`](sorter.php) | anywhere PHP 7.1+ runs |

---

## 🗂 Why?

Your downloads folder is a graveyard of random files:

```
Downloads/
├── song_final_FINAL.mp3
├── screenshot_2026-01-01.png
├── thesis.pdf
├── setup.exe
├── backup.tar.gz
└── ...143 more files you'll never find again
```

Run one command and it becomes:

```
Downloads/
├── Music/
│   └── song_final_FINAL.mp3
├── Image/
│   └── screenshot_2026-01-01.png
├── Pdf/
│   └── thesis.pdf
├── Executables/
│   └── setup.exe
└── Archives/
    └── backup.tar.gz
```

## ✨ Features

- 🔤 **5 languages, one brain** — identical CLI, categories and output in
  Bash, Python, CMD, PowerShell and PHP.
- 📁 **Folders on demand** — a category folder is only created when there is
  actually a file for it. No empty folders.
- 🛡 **Never overwrites** — if `Music/song.mp3` already exists, your file
  becomes `Music/song_1.mp3`, then `song_2.mp3`, and so on.
- 👻 **Case-insensitive** — `.JPG`, `.Mp3` and `.pdf` all match.
- 🧪 **Dry-run mode** — see exactly what would happen, change nothing:
  `sorter.sh --dry-run`.
- 🎯 **Multi-dot aware** — `backup.tar.gz` is an archive, not "tar.gz".
- 🌪 **Non-invasive** — subfolders and hidden files are left untouched;
  files with unknown extensions stay where they are and are reported.
- ⚙️ **Portable** — no dependencies, no installation. One file per language.
- 📊 **Summary report** — files sorted, folders touched, files left unchanged.

## 🚀 Quick start

### 🐚 Linux / macOS / WSL / Android (Termux)

```sh
# clone the repo (or just download sorter.sh)
git clone https://github.com/isme8349-cmd/download-folder-sorter.git
cd download-folder-sorter
chmod +x sorter.sh

# sort your downloads
./sorter.sh ~/Downloads

# or run it straight from GitHub, without cloning:
bash <(curl -fsSL https://raw.githubusercontent.com/isme8349-cmd/download-folder-sorter/main/sorter.sh) ~/Downloads
```

> 📱 **Termux (Android):** run `termux-setup-storage` once to grant
> permission, then `./sorter.sh ~/storage/downloads`.

### 🐍 Python

```sh
python3 sorter.py ~/Downloads
```

### 💾 Windows — CMD

Double-click `sorter.bat`, or from a terminal:

```bat
sorter.bat C:\Users\you\Downloads
```

### 🪟 Windows — PowerShell

```powershell
.\sorter.ps1 C:\Users\you\Downloads

# if you get a "cannot load because running scripts is disabled" error:
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 🐘 PHP

```sh
php sorter.php ~/Downloads
```

If you omit the folder argument, the script sorts your **downloads folder**
automatically (`~/storage/downloads` when it exists, otherwise `~/Downloads`).

## 🎛 Options

The same options work in every language (PowerShell uses its own casing):

| Option | PowerShell | Description |
|--------|-----------|-------------|
| `folder` | `Folder` | Folder to sort (positional, optional). |
| `-n`, `--dry-run` | `-DryRun`, `-n` | Show what would be moved, change nothing. |
| `-l`, `--list` | `-List`, `-l` | Print the category → extension mapping. |
| `-h`, `--help` | `-ShowHelp`, `-h` | Show help. |
| `-v`, `--version` | `-ShowVersion`, `-v` | Print the version. |

Exit codes: `0` success · `1` folder not found / I/O error · `2` bad usage.

### Example run

```console
$ ./sorter.sh ~/Downloads
Sorted: song.MP3      -> Music/
Sorted: photo.JPG     -> Image/
Sorted: thesis.pdf    -> Pdf/
Sorted: backup.tar.gz -> Archives/

Sorted 4 file(s) into: Music, Image, Pdf, Archives. 2 file(s) left unchanged.
```

## 🗃 Supported categories

| Folder | Extensions |
|--------|-----------|
| 🎵 `Music` | mp3 wav ogg flac m4a wma aac opus mid midi |
| 🖼️ `Image` | jpg jpeg png webp gif bmp svg ico tiff tif heic avif |
| 🎬 `Video` | mp4 mkv avi mov flv wmv webm m4v |
| 📄 `Pdf` | pdf |
| 📊 `Office` | doc docx xls xlsx ppt pptx rtf odt ods odp |
| 📝 `Text` | txt log md csv tsv json xml yaml yml ini conf |
| 💻 `Code` | py js ts html css c cpp h cs go rs java rb php sh bash ps1 sql |
| 📦 `Archives` | zip rar 7z tar gz bz2 xz |
| 🔤 `Fonts` | ttf otf woff woff2 |
| ⚙️ `Executables` | exe msi jar apk xapk deb rpm appimage bat cmd |
| 💿 `Iso` | iso img vhd vmdk |

Run `sorter.sh --list` (or any other edition) to print this table.

## 🛠 Customization

Every edition stores the mapping in one clearly-marked block near the top of
the file — edit it and you're done.

- **Bash:** the `CATEGORIES` array — `"Folder:ext1 ext2 …"` per line.
- **Python:** the `CATEGORIES` dictionary.
- **CMD:** the `set "CAT_*=…"` lines and the `call :sort_folder` lines.
- **PowerShell:** the `$script:Categories` ordered dictionary.
- **PHP:** the `CATEGORIES` constant.

Rules of thumb:

- Extensions are matched **case-insensitively** — list them in lowercase.
- Keep each extension in **one category only** (the first match wins).
- Files with extensions not in the table are **left alone** — add a category
  if you want them moved.

## 🔄 v2.0 — what's new

- New Python, CMD, PowerShell and PHP editions (same behavior everywhere).
- CLI: target folder as an argument, `--dry-run`, `--list`, `--help`, `--version`.
- Collision-safe moves: `name_1.ext`, `name_2.ext` (the old `mv -n` silently
  skipped clashing files).
- Case-insensitive matching and multi-dot extensions (`a.tar.gz` → Archives).
- Summary report and proper exit codes.


## 📄 License

[Apache License 2.0](LICENSE) © isme8349-cmd
