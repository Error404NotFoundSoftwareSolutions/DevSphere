# Build the DevPilot desktop app for Windows, with everything the "open lab in VS Code" flow needs. Windows version of
# tools/build_linux.sh. Run it on a Windows 10/11 PC (Flutter cannot build Windows apps on Linux or macOS):
#
#     powershell -ExecutionPolicy Bypass -File tools\build_windows.ps1
#
# Needs, on PATH: Flutter (stable, with "flutter doctor" green for Windows desktop, which means Visual Studio 2022
# with the "Desktop development with C++" workload), Git and Node.js 22. Dart comes with Flutter.
#   - the guide extension packaged as a .vsix, with a metadata file holding its SHA-256
#   - the local worker compiled to worker.exe
#   - the Flutter app, with worker.exe, guide\ and content\labs placed next to devpilot.exe
# Output: release\devpilot-windows-x64-setup.exe (an installer, built with Inno Setup when it is available) and
# release\devpilot-windows-x64.zip (a portable copy that unpacks into a devpilot\ folder), each with a .sha256 file.
# Lab content is bundled WITHOUT its private parts (no reference\, no tests\protected, no AUTHORING.md).
# The hosted service is the default address (DEVPILOT_API_URL still overrides it at run time). When
# DEVPILOT_GOOGLE_CLIENT_SECRET is in .env or the environment, the Google sign-in client secret is compiled in. Google
# treats a desktop app's client secret as non-confidential, but anyone with the file can extract it. Nothing is printed
# or committed (release\ is git-ignored).
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Out = Join-Path $Root "release"
$Ext = Join-Path $Root "extensions\devsphere-learn"
$Bundle = Join-Path $Out "devpilot"
$GuideBuild = Join-Path $Out "guide-build"

function Run([scriptblock]$Block, [string]$What) {
  & $Block
  if ($LASTEXITCODE -ne 0) { throw "FAILED ($LASTEXITCODE): $What" }
}
function Need([string]$Cmd, [string]$Hint) {
  if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) { throw "'$Cmd' was not found on PATH. $Hint" }
}
function WriteText([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

Need flutter "Install Flutter: https://docs.flutter.dev/get-started/install/windows/desktop"
Need dart "Dart comes with Flutter; check that Flutter's bin folder is on PATH."
Need node "Install Node.js 22: https://nodejs.org"
Need npm "Install Node.js 22: https://nodejs.org"
Need git "Install Git for Windows: https://git-scm.com"
Need tar "tar.exe ships with Windows 10 (1803) and newer."

if (Test-Path $Bundle) { Remove-Item -Recurse -Force $Bundle }
if (Test-Path $GuideBuild) { Remove-Item -Recurse -Force $GuideBuild }
New-Item -ItemType Directory -Force $GuideBuild | Out-Null

Write-Host "== extension: install, test, package"
Push-Location $Ext
Run { npm ci --ignore-scripts } "npm ci"
Run { npm test } "extension tests"
$Version = (Get-Content (Join-Path $Ext "package.json") -Raw | ConvertFrom-Json).version
$Vsix = "devpilot-guide-$Version.vsix"
Run { npx vsce package --no-dependencies --allow-missing-repository --skip-license -o (Join-Path $GuideBuild $Vsix) } "vsce package"
$Pkg = Get-Content (Join-Path $Ext "package.json") -Raw | ConvertFrom-Json
$ExtId = "$($Pkg.publisher).$($Pkg.name)"
Pop-Location
$Sha = (Get-FileHash (Join-Path $GuideBuild $Vsix) -Algorithm SHA256).Hash.ToLower()
WriteText (Join-Path $GuideBuild "devpilot-guide.json") ('{"id":"' + $ExtId + '","version":"' + $Version + '","sha256":"' + $Sha + '","vsix":"' + $Vsix + '"}' + "`n")

Write-Host "== worker: compile"
Push-Location (Join-Path $Root "services\local-worker")
Run { dart pub get } "dart pub get (worker)"
Run { dart compile exe bin\worker.dart -o (Join-Path $GuideBuild "worker.exe") } "dart compile exe"
Pop-Location

Write-Host "== app: flutter build windows (release)"
$ApiUrl = $env:DEVPILOT_DEFAULT_API_URL
if (-not $ApiUrl) { $ApiUrl = "https://devpilot-api-664564860639.asia-south1.run.app" }
$Defines = @("--dart-define=DEVPILOT_DEFAULT_API_URL=$ApiUrl")
$Secret = $env:DEVPILOT_GOOGLE_CLIENT_SECRET
$EnvFile = Join-Path $Root ".env"
if (-not $Secret -and (Test-Path $EnvFile)) {
  $line = Select-String -Path $EnvFile -Pattern '^DEVPILOT_GOOGLE_CLIENT_SECRET=' | Select-Object -First 1
  if ($line) { $Secret = $line.Line.Substring($line.Line.IndexOf('=') + 1).Trim() }
}
if ($Secret) {
  $Defines += "--dart-define=DEVPILOT_GOOGLE_CLIENT_SECRET=$Secret"
  Write-Host "   Google sign-in secret: compiled in"
} else {
  Write-Host "   Google sign-in secret: NOT set (Google sign-in will not work; email sign-up will)"
}
Write-Host "   default service: $ApiUrl"
Push-Location (Join-Path $Root "apps\desktop")
Run { flutter build windows --release @Defines } "flutter build windows"
Pop-Location
$Secret = $null; $Defines = $null

Write-Host "== assemble"
$Built = Join-Path $Root "apps\desktop\build\windows\x64\runner\Release"
if (-not (Test-Path (Join-Path $Built "devpilot.exe"))) { throw "devpilot.exe was not produced in $Built" }
New-Item -ItemType Directory -Force $Bundle | Out-Null
Copy-Item -Recurse -Force (Join-Path $Built "*") $Bundle
New-Item -ItemType Directory -Force (Join-Path $Bundle "guide") | Out-Null
Copy-Item (Join-Path $GuideBuild $Vsix) (Join-Path $Bundle "guide")
Copy-Item (Join-Path $GuideBuild "devpilot-guide.json") (Join-Path $Bundle "guide")
Copy-Item (Join-Path $GuideBuild "worker.exe") (Join-Path $Bundle "worker.exe")
# the Visual C++ runtime, next to the app, so it starts on a PC that has not installed the redistributable
foreach ($dll in "msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll") {
  $src = Join-Path $env:SystemRoot "System32\$dll"
  if ((Test-Path $src) -and -not (Test-Path (Join-Path $Bundle $dll))) { Copy-Item $src $Bundle }
}

Write-Host "== lab content (public parts only)"
$LabsOut = Join-Path $Bundle "content\labs"
New-Item -ItemType Directory -Force $LabsOut | Out-Null
foreach ($lab in Get-ChildItem -Directory (Join-Path $Root "content\labs")) {
  $dest = Join-Path $LabsOut $lab.Name
  # everything except the private parts: reference solutions, protected tests, authoring notes
  & robocopy $lab.FullName $dest /E /NFL /NDL /NJH /NJS /NP /XD (Join-Path $lab.FullName "reference") (Join-Path $lab.FullName "tests\protected") /XF AUTHORING.md | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $($lab.Name) (exit $LASTEXITCODE)" }
}
$leak = Get-ChildItem -Recurse -Force (Join-Path $Bundle "content") | Where-Object { $_.Name -in @("reference", "protected", "AUTHORING.md") }
if ($leak) { throw "private lab parts leaked into the package: $($leak.FullName -join ', ')" }

Write-Host "== start menu entry and notes"
$Install = @'
# Adds DevPilot to the Start menu (for this user only). Run it once from this folder:
#   powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $here "devpilot.exe"
$dir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk = Join-Path $dir "DevPilot.lnk"
$sh = New-Object -ComObject WScript.Shell
$s = $sh.CreateShortcut($lnk)
$s.TargetPath = $exe
$s.WorkingDirectory = $here
$s.IconLocation = "$exe,0"
$s.Description = "Learn practical engineering skills with guided labs"
$s.Save()
Write-Host "DevPilot added to your Start menu."
'@
WriteText (Join-Path $Bundle "install.ps1") $Install
$Readme = @'
DevPilot for Windows
====================
Run:   double-click devpilot.exe   (or run install.ps1 once to add DevPilot to the Start menu)
Needs: Windows 10 or 11 (64-bit), VS Code (the `code` command on PATH), Python 3.10+, Git, and an internet connection.
Optional: set DEVPILOT_API_URL to use another DevPilot service. Sign in with email, or with Google.
Notes: learning paths, videos, the tutor and the coach use the online DevPilot service. Writing new AI labs needs the
developer setup (the project's start script) and is not available from this package.
This preview is not code-signed, so Windows SmartScreen may say "Windows protected your PC": choose "More info", then
"Run anyway". Check the download first with the .sha256 file from the release page.
'@
WriteText (Join-Path $Bundle "README.txt") $Readme

Write-Host "== zip and checksum"
$Zip = Join-Path $Out "devpilot-windows-x64.zip"
if (Test-Path $Zip) { Remove-Item -Force $Zip }
Run { tar.exe -a -c -f $Zip -C $Out devpilot } "zip the package"
$Hash = (Get-FileHash $Zip -Algorithm SHA256).Hash.ToLower()
WriteText "$Zip.sha256" "$Hash  devpilot-windows-x64.zip`n"
$sizeMb = [math]::Round((Get-Item $Zip).Length / 1MB)
Write-Host "Built: $Bundle\devpilot.exe, package $Zip ($sizeMb MB)"
Write-Host "SHA-256: $Hash"

Write-Host "== installer (Inno Setup)"
function FindIscc {
  $c = @("${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:ProgramFiles\Inno Setup 6\ISCC.exe", "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $c) { $g = Get-Command iscc -ErrorAction SilentlyContinue; if ($g) { $c = $g.Source } }
  return $c
}
$Iscc = FindIscc
if (-not $Iscc -and $env:CI -and (Get-Command choco -ErrorAction SilentlyContinue)) {
  choco install innosetup -y --no-progress | Out-Null
  $Iscc = FindIscc
}
if ($Iscc) {
  $verLine = Select-String -Path (Join-Path $Root "apps\desktop\pubspec.yaml") -Pattern '^version:\s*(\d+\.\d+\.\d+)' | Select-Object -First 1
  $AppVer = if ($verLine) { $verLine.Matches[0].Groups[1].Value } else { "0.1.0" }
  Run { & $Iscc /Q "/DAppVersion=$AppVer" "/DSourceDir=$Bundle" (Join-Path $Root "tools\windows_installer.iss") } "Inno Setup"
  $Setup = Join-Path $Out "devpilot-windows-x64-setup.exe"
  if (-not (Test-Path $Setup)) { throw "the installer was not produced" }
  $SetupHash = (Get-FileHash $Setup -Algorithm SHA256).Hash.ToLower()
  WriteText "$Setup.sha256" "$SetupHash  devpilot-windows-x64-setup.exe`n"
  Write-Host "Installer: $Setup ($([math]::Round((Get-Item $Setup).Length / 1MB)) MB)"
  Write-Host "SHA-256: $SetupHash"
} else {
  Write-Host "Inno Setup 6 was not found, so no installer was made (install it from jrsoftware.org, or run this on a GitHub runner). The zip is still complete."
}
