# Changelog

All notable changes to this project.

## [2.0.0] — 2026-09-17

### Added
- Python edition: `sorter.py` (Python 3.7+, standard library only).
- Windows CMD edition: `sorter.bat`.
- Windows PowerShell edition: `sorter.ps1` (Windows PowerShell 5.1+ / PowerShell 7+).
- PHP edition: `sorter.php` (PHP 7.1+).
- CLI options in every edition: positional target folder, `-n/--dry-run`,
  `-l/--list`, `-h/--help`, `-v/--version`.
- Summary report: files sorted, folders touched, files left unchanged.
- Proper exit codes: `0` success, `1` folder not found / I/O error, `2` bad usage.

### Changed
- Bash `sorter.sh`: collision-safe moves — clashing files are renamed to
  `name_1.ext`, `name_2.ext`, … instead of being silently skipped (`mv -n`).
- Extension matching is now case-insensitive in every edition (`.JPG` → Image).
- Multi-dot file names are handled: `backup.tar.gz` → `Archives`.
- Default folder: `~/storage/downloads` (Termux) when it exists, otherwise
  `~/Downloads`; an explicit folder argument always wins.
- README rewritten with full documentation for all editions.
- Fixed the license stated in the README (it is Apache-2.0, matching LICENSE).

## [1.1]

- Original Bash-only version: hardcoded `~/storage/downloads` target,
  create folders on demand, safe `mv -n` moves.
