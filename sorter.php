#!/usr/bin/env php
<?php
/**
 * Universal Folder Sorter — PHP edition (v2.0.0)
 *
 * Sorts the files in a folder into subfolders by file type.
 * Folders are created only when needed, existing files are never
 * overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).
 *
 * Usage: php sorter.php [folder] [options]
 */

declare(strict_types=1);

const VERSION = '2.0.0';

/** category -> extensions (matched case-insensitively) */
const CATEGORIES = [
    'Music'       => ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'wma', 'aac', 'opus', 'mid', 'midi'],
    'Image'       => ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'ico', 'tiff', 'tif', 'heic', 'avif'],
    'Video'       => ['mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 'webm', 'm4v'],
    'Pdf'         => ['pdf'],
    'Office'      => ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'rtf', 'odt', 'ods', 'odp'],
    'Text'        => ['txt', 'log', 'md', 'csv', 'tsv', 'json', 'xml', 'yaml', 'yml', 'ini', 'conf'],
    'Code'        => ['py', 'js', 'ts', 'html', 'css', 'c', 'cpp', 'h', 'cs', 'go', 'rs', 'java', 'rb', 'php', 'sh', 'bash', 'ps1', 'sql'],
    'Archives'    => ['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'],
    'Fonts'       => ['ttf', 'otf', 'woff', 'woff2'],
    'Executables' => ['exe', 'msi', 'jar', 'apk', 'xapk', 'deb', 'rpm', 'appimage', 'bat', 'cmd'],
    'Iso'         => ['iso', 'img', 'vhd', 'vmdk'],
];

/** @return array<string, string> lowercase extension -> category */
function extToCategoryMap(): array
{
    static $map = null;
    if ($map === null) {
        $map = [];
        foreach (CATEGORIES as $name => $exts) {
            foreach ($exts as $ext) {
                $map[$ext] = $name;
            }
        }
    }
    return $map;
}

function usage(): void
{
    $help = [
        'Universal Folder Sorter v' . VERSION . ' (PHP)',
        '',
        'Sorts files in a folder into subfolders by file type.',
        'Folders are created only when needed, and existing files are never',
        'overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).',
        '',
        'Usage:',
        '  php sorter.php [folder] [options]',
        '',
        'Arguments:',
        '  folder         Folder to sort. Default: ~/storage/downloads when it',
        '                 exists, otherwise ~/Downloads.',
        '',
        'Options:',
        '  -n, --dry-run  Show what would be moved without moving anything.',
        '  -l, --list     Print the category -> extension mapping and exit.',
        '  -h, --help     Show this help and exit.',
        '  -v, --version  Print the version and exit.',
        '',
        'Examples:',
        '  php sorter.php',
        '  php sorter.php ~/Downloads',
        '  php sorter.php ~/Downloads --dry-run',
    ];
    echo implode(PHP_EOL, $help) . PHP_EOL;
}

function listCategories(): void
{
    echo 'Universal Folder Sorter v' . VERSION . ' (PHP) — categories:' . PHP_EOL;
    foreach (CATEGORIES as $name => $exts) {
        printf("  %-12s : %s%s", $name, implode(' ', $exts), PHP_EOL);
    }
}

function defaultFolder(): string
{
    $home = getenv('HOME') ?: (getenv('USERPROFILE') ?: sys_get_temp_dir());
    $candidates = [$home . '/storage/downloads', $home . '/Downloads'];
    foreach ($candidates as $candidate) {
        if (is_dir($candidate)) {
            return $candidate;
        }
    }
    return $home . '/Downloads';
}

/** Parse argv (excluding the script name). @return array{folder:string|null,dry_run:bool} */
function parseArgs(array $argv): array
{
    $args = ['folder' => null, 'dry_run' => false];
    foreach ($argv as $arg) {
        switch ($arg) {
            case '-h':
            case '--help':
                usage();
                exit(0);
            case '-v':
            case '--version':
                echo 'Universal Folder Sorter v' . VERSION . ' (PHP)' . PHP_EOL;
                exit(0);
            case '-l':
            case '--list':
                listCategories();
                exit(0);
            case '-n':
            case '--dry-run':
                $args['dry_run'] = true;
                break;
            default:
                if ($arg !== '' && $arg[0] === '-' && strlen($arg) > 1) {
                    fwrite(STDERR, 'Error: unknown option: ' . $arg . PHP_EOL);
                    exit(2);
                }
                if ($args['folder'] !== null) {
                    fwrite(STDERR, 'Error: only one folder argument is allowed.' . PHP_EOL);
                    exit(2);
                }
                $args['folder'] = $arg;
        }
    }
    return $args;
}

/** Lowercase extension of a file name, or '' (leading dot = no extension). */
function fileExtension(string $name): string
{
    $dot = strrpos($name, '.');
    if ($dot === false || $dot === 0) {
        return '';
    }
    $ext = substr($name, $dot + 1);
    return $ext === '' ? '' : strtolower($ext);
}

/** Return a destination inside $destDir that does not exist yet. */
function resolveDest(string $destDir, string $name): string
{
    $dest = $destDir . DIRECTORY_SEPARATOR . $name;
    if (!file_exists($dest) && !is_link($dest)) {
        return $dest;
    }
    $dot = strrpos($name, '.');
    if ($dot === false) {
        $stem = $name;
        $dotExt = '';
    } else {
        $stem = substr($name, 0, $dot);
        $dotExt = substr($name, $dot);
    }
    $n = 0;
    do {
        $n++;
        $dest = $destDir . DIRECTORY_SEPARATOR . $stem . '_' . $n . $dotExt;
    } while (file_exists($dest) || is_link($dest));
    return $dest;
}

$args = parseArgs(array_slice($argv, 1));

$target = $args['folder'] !== null ? $args['folder'] : defaultFolder();
if (!is_dir($target)) {
    fwrite(STDERR, 'Error: folder not found: ' . $target . PHP_EOL);
    exit(1);
}

$map = extToCategoryMap();
$moved = 0;
$unchanged = 0;
$touched = [];

$entries = scandir($target);
if ($entries === false) {
    fwrite(STDERR, 'Error: cannot read folder: ' . $target . PHP_EOL);
    exit(1);
}
usort($entries, 'strnatcasecmp');

foreach ($entries as $entry) {
    if ($entry === '.' || $entry === '..') {
        continue;
    }
    $path = $target . DIRECTORY_SEPARATOR . $entry;
    if (!is_file($path)) {
        continue; // skip subfolders, hidden files, etc.
    }

    $ext = fileExtension($entry);
    $category = $ext !== '' && isset($map[$ext]) ? $map[$ext] : null;
    if ($category === null) {
        $unchanged++;
        continue;
    }

    $destDir = $target . DIRECTORY_SEPARATOR . $category;
    if ($args['dry_run']) {
        echo '[dry-run] ' . $entry . ' -> ' . $category . '/' . PHP_EOL;
    } else {
        if (!is_dir($destDir) && !mkdir($destDir, 0777, true)) {
            fwrite(STDERR, 'Error: cannot create folder: ' . $destDir . PHP_EOL);
            exit(1);
        }
        $dest = resolveDest($destDir, $entry);
        if (!rename($path, $dest)) {
            fwrite(STDERR, 'Error: could not move ' . $entry . ' -> ' . $dest . PHP_EOL);
            exit(1);
        }
        echo 'Sorted: ' . $entry . ' -> ' . $category . '/' . PHP_EOL;
    }

    $moved++;
    if (!isset($touched[$category])) {
        $touched[$category] = true;
    }
}

$where = $touched ? ' into: ' . implode(', ', array_keys($touched)) : '';
if ($args['dry_run']) {
    echo PHP_EOL . "[dry-run] Would sort {$moved} file(s){$where}. "
        . "{$unchanged} file(s) left unchanged. Nothing was moved." . PHP_EOL;
} else {
    echo PHP_EOL . "Sorted {$moved} file(s){$where}. "
        . "{$unchanged} file(s) left unchanged." . PHP_EOL;
}
exit(0);
