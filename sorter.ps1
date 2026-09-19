<#
.SYNOPSIS
    Universal Folder Sorter - PowerShell edition (v2.0.0)

.DESCRIPTION
    Sorts the files in a folder into subfolders by file type.
    Folders are created only when needed, existing files are never
    overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).

.PARAMETER Folder
    Folder to sort. Default: $HOME\storage\downloads when it exists,
    otherwise $HOME\Downloads.

.PARAMETER DryRun
    Show what would be moved without moving anything. (alias: n)

.PARAMETER ShowHelp
    Show help and exit. (alias: h)

.PARAMETER ShowVersion
    Print the version and exit. (alias: v)

.PARAMETER List
    Print the category -> extension mapping and exit. (alias: l)

.EXAMPLE
    .\sorter.ps1

.EXAMPLE
    .\sorter.ps1 C:\Users\me\Downloads -DryRun

.EXAMPLE
    .\sorter.ps1 -List
#>
param(
    [Parameter(Position = 0)]
    [string]$Folder = '',

    [Parameter(Alias = 'n')]
    [switch]$DryRun,

    [Parameter(Alias = 'h')]
    [switch]$ShowHelp,

    [Parameter(Alias = 'v')]
    [switch]$ShowVersion,

    [Parameter(Alias = 'l')]
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$script:VersionNumber = '2.0.0'

# category -> extensions (matched case-insensitively)
$script:Categories = [ordered]@{
    'Music'       = @('mp3', 'wav', 'ogg', 'flac', 'm4a', 'wma', 'aac', 'opus', 'mid', 'midi')
    'Image'       = @('jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'ico', 'tiff', 'tif', 'heic', 'avif')
    'Video'       = @('mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 'webm', 'm4v')
    'Pdf'         = @('pdf')
    'Office'      = @('doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'rtf', 'odt', 'ods', 'odp')
    'Text'        = @('txt', 'log', 'md', 'csv', 'tsv', 'json', 'xml', 'yaml', 'yml', 'ini', 'conf')
    'Code'        = @('py', 'js', 'ts', 'html', 'css', 'c', 'cpp', 'h', 'cs', 'go', 'rs', 'java', 'rb', 'php', 'sh', 'bash', 'ps1', 'sql')
    'Archives'    = @('zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz')
    'Fonts'       = @('ttf', 'otf', 'woff', 'woff2')
    'Executables' = @('exe', 'msi', 'jar', 'apk', 'xapk', 'deb', 'rpm', 'appimage', 'bat', 'cmd')
    'Iso'         = @('iso', 'img', 'vhd', 'vmdk')
}

$script:ExtToCategory = @{}
foreach ($name in $script:Categories.Keys) {
    foreach ($ext in $script:Categories[$name]) {
        $script:ExtToCategory[$ext] = $name
    }
}

function Show-Help {
    Write-Host "Universal Folder Sorter v$($script:VersionNumber) (PowerShell)"
    Write-Host @'

Sorts files in a folder into subfolders by file type.
Folders are created only when needed, and existing files are never
overwritten (clashes are renamed to name_1.ext, name_2.ext, ...).

Usage:
  .\sorter.ps1 [Folder] [options]

Arguments:
  Folder         Folder to sort. Default: $HOME\storage\downloads when it
                 exists, otherwise $HOME\Downloads.

Options:
  -DryRun, -n    Show what would be moved without moving anything.
  -List, -l      Print the category -> extension mapping and exit.
  -ShowHelp, -h  Show this help and exit.
  -ShowVersion, -v
                 Print the version and exit.

Examples:
  .\sorter.ps1
  .\sorter.ps1 C:\Users\me\Downloads
  .\sorter.ps1 C:\Users\me\Downloads -DryRun
'@
}

function Show-List {
    Write-Host "Universal Folder Sorter v$($script:VersionNumber) (PowerShell) - categories:"
    foreach ($name in $script:Categories.Keys) {
        Write-Host ("  {0,-12} : {1}" -f $name, ($script:Categories[$name] -join ' '))
    }
}

if ($ShowVersion) {
    Write-Host "Universal Folder Sorter v$($script:VersionNumber) (PowerShell)"
    exit 0
}
if ($ShowHelp) { Show-Help; exit 0 }
if ($List) { Show-List; exit 0 }

if (-not $Folder) {
    foreach ($candidate in @("$HOME\storage\downloads", "$HOME\Downloads")) {
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $Folder = $candidate
            break
        }
    }
    if (-not $Folder) { $Folder = "$HOME\Downloads" }
}

if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
    Write-Host "Error: folder not found: $Folder" -ForegroundColor Red
    exit 1
}

$moved = 0
$unchanged = 0
$touched = [System.Collections.Generic.List[string]]::new()

foreach ($item in (Get-ChildItem -LiteralPath $Folder -File | Sort-Object Name)) {
    $ext = if ($item.Extension) { $item.Extension.TrimStart('.').ToLowerInvariant() } else { '' }
    $category = $null
    if ($ext -ne '' -and $script:ExtToCategory.Contains($ext)) {
        $category = $script:ExtToCategory[$ext]
    }
    if ($null -eq $category) {
        $unchanged++
        continue
    }

    $destDir = Join-Path $Folder $category
    if ($DryRun) {
        Write-Host "[dry-run] $($item.Name) -> $category\"
    }
    else {
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $dest = Join-Path $destDir $item.Name
        if (Test-Path -LiteralPath $dest) {
            $n = 1
            do {
                $dest = Join-Path $destDir ("{0}_{1}{2}" -f $item.BaseName, $n, $item.Extension)
                $n++
            } while (Test-Path -LiteralPath $dest)
        }
        Move-Item -LiteralPath $item.FullName -Destination $dest
        Write-Host "Sorted: $($item.Name) -> $category\"
    }

    $moved++
    if (-not $touched.Contains($category)) { $touched.Add($category) }
}

Write-Host ''
$where = if ($touched.Count -gt 0) { " into: {0}" -f ($touched -join ', ') } else { '' }
if ($DryRun) {
    Write-Host "[dry-run] Would sort $moved file(s)$where. $unchanged file(s) left unchanged. Nothing was moved."
}
else {
    Write-Host "Sorted $moved file(s)$where. $unchanged file(s) left unchanged."
}
exit 0
