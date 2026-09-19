@echo off
rem ============================================================
rem  Universal Folder Sorter - CMD edition (v2.0.0)
rem  Sorts the files in a folder into subfolders by file type.
rem  Folders are created only when needed, existing files are
rem  never overwritten (clashes become name_1.ext, name_2.ext).
rem
rem  Usage: sorter.bat [folder] [--dry-run]
rem ============================================================
setlocal EnableExtensions

set "VERSION=2.0.0"
set "DRY_RUN=0"
set "TARGET="
set "MOVED=0"
set "TOUCHED="

rem ---- categories (space separated, case-insensitive) -------
set "CAT_MUSIC=mp3 wav ogg flac m4a wma aac opus mid midi"
set "CAT_IMAGE=jpg jpeg png webp gif bmp svg ico tiff tif heic avif"
set "CAT_VIDEO=mp4 mkv avi mov flv wmv webm m4v"
set "CAT_PDF=pdf"
set "CAT_OFFICE=doc docx xls xlsx ppt pptx rtf odt ods odp"
set "CAT_TEXT=txt log md csv tsv json xml yaml yml ini conf"
set "CAT_CODE=py js ts html css c cpp h cs go rs java rb php sh bash ps1 sql"
set "CAT_ARCHIVES=zip rar 7z tar gz bz2 xz"
set "CAT_FONTS=ttf otf woff woff2"
set "CAT_EXECUTABLES=exe msi jar apk xapk deb rpm appimage bat cmd"
set "CAT_ISO=iso img vhd vmdk"

rem ---- argument parsing -------------------------------------
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--dry-run" set "DRY_RUN=1" & shift & goto parse_args
if /i "%~1"=="-n" set "DRY_RUN=1" & shift & goto parse_args
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--version" (echo Universal Folder Sorter v%VERSION% ^(CMD^) & exit /b 0)
if /i "%~1"=="-v" (echo Universal Folder Sorter v%VERSION% ^(CMD^) & exit /b 0)
if /i "%~1"=="--list" goto show_list
if /i "%~1"=="-l" goto show_list
if not defined TARGET (set "TARGET=%~1") else (echo Error: only one folder argument is allowed. & exit /b 2)
shift
goto parse_args

:args_done
if not defined TARGET (
  if exist "%USERPROFILE%\storage\downloads\" set "TARGET=%USERPROFILE%\storage\downloads"
)
if not defined TARGET (
  if exist "%USERPROFILE%\Downloads\" set "TARGET=%USERPROFILE%\Downloads"
)
if not defined TARGET (
  echo Error: no folder argument given and no default downloads folder found.
  exit /b 1
)
if not exist "%TARGET%\" (
  echo Error: folder not found: %TARGET%
  exit /b 1
)

rem ---- sorting ----------------------------------------------
call :sort_folder "Music" %CAT_MUSIC%
call :sort_folder "Image" %CAT_IMAGE%
call :sort_folder "Video" %CAT_VIDEO%
call :sort_folder "Pdf" %CAT_PDF%
call :sort_folder "Office" %CAT_OFFICE%
call :sort_folder "Text" %CAT_TEXT%
call :sort_folder "Code" %CAT_CODE%
call :sort_folder "Archives" %CAT_ARCHIVES%
call :sort_folder "Fonts" %CAT_FONTS%
call :sort_folder "Executables" %CAT_EXECUTABLES%
call :sort_folder "Iso" %CAT_ISO%

rem ---- summary ----------------------------------------------
echo.
if "%DRY_RUN%"=="1" (
  if defined TOUCHED (echo [dry-run] Would sort %MOVED% file(s) into: %TOUCHED%. Nothing was moved.) else (echo [dry-run] Nothing to sort - no matching files found.)
) else (
  if defined TOUCHED (echo Sorted %MOVED% file(s) into: %TOUCHED%.) else (echo No files to sort.)
)
exit /b 0

rem ============================================================
:sort_folder
rem  %1 = folder name, rest = extensions
set "CAT=%~1"
set "CAT_MOVED=0"
shift
for %%e in (%*) do (
  for /f "delims=" %%F in ('dir /a-d /b "%TARGET%\*.%%e" 2^>nul') do call :move_file "%%F" "%CAT%"
)
if %CAT_MOVED% gtr 0 (
  if defined TOUCHED (set "TOUCHED=%TOUCHED% %CAT%") else (set "TOUCHED=%CAT%")
)
goto :eof

rem ============================================================
:move_file
rem  %1 = file name (already inside %TARGET%), %2 = category
set "NAME=%~1"
set "DEST=%TARGET%\%CAT%\%NAME%"
if not exist "%DEST%" goto ufs_do_move
set "BASE=%~n1"
set "EXT=%~x1"
set /a CLASH=0
:ufs_find_slot
set /a CLASH+=1
set "DEST=%TARGET%\%CAT%\%BASE%_%CLASH%%EXT%"
if exist "%DEST%" goto ufs_find_slot
:ufs_do_move
if "%DRY_RUN%"=="1" (
  echo [dry-run] %NAME% -^> %CAT%\
) else (
  if not exist "%TARGET%\%CAT%\" mkdir "%TARGET%\%CAT%"
  move /y "%TARGET%\%NAME%" "%DEST%" >nul
  if errorlevel 1 (
    echo Warning: could not move %NAME% - file locked or read-only?
  ) else (
    echo Sorted: %NAME% -^> %CAT%\
  )
)
set /a MOVED+=1
set /a CAT_MOVED+=1
goto :eof

rem ============================================================
:show_help
echo Universal Folder Sorter v%VERSION% ^(CMD^)
echo.
echo Sorts files in a folder into subfolders by file type.
echo Folders are created only when needed, and existing files are
echo never overwritten (clashes become name_1.ext, name_2.ext, ...).
echo.
echo Usage: sorter.bat [folder] [options]
echo.
echo Arguments:
echo   folder         Folder to sort. Default: %%USERPROFILE%%\Downloads
echo                  (%%USERPROFILE%%\storage\downloads if it exists).
echo.
echo Options:
echo   -n, --dry-run  Show what would be moved without moving anything.
echo   -l, --list     Print the category -^> extension mapping and exit.
echo   -h, --help     Show this help and exit.
echo   -v, --version  Print the version and exit.
echo.
echo Examples:
echo   sorter.bat
echo   sorter.bat C:\Downloads
echo   sorter.bat C:\Downloads --dry-run
exit /b 0

rem ============================================================
:show_list
echo Universal Folder Sorter v%VERSION% ^(CMD^) - categories:
echo   Music       : %CAT_MUSIC%
echo   Image       : %CAT_IMAGE%
echo   Video       : %CAT_VIDEO%
echo   Pdf         : %CAT_PDF%
echo   Office      : %CAT_OFFICE%
echo   Text        : %CAT_TEXT%
echo   Code        : %CAT_CODE%
echo   Archives    : %CAT_ARCHIVES%
echo   Fonts       : %CAT_FONTS%
echo   Executables : %CAT_EXECUTABLES%
echo   Iso         : %CAT_ISO%
exit /b 0
