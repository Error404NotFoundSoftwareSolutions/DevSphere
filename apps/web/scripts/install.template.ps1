# DevPilot for Windows: one-command install.
#
#   irm https://devpilot.web.app/install.ps1 | iex
#
# What this script does, and nothing else:
#   1. checks that this is 64-bit Windows,
#   2. downloads the DevPilot installer from the public release (__URL__),
#   3. checks its SHA-256 against the value written in this script, and stops if it does not match,
#   4. runs the installer for your user only (no administrator rights),
#   5. starts DevPilot.
# It changes nothing else on your computer. You can read it before you run it; it is short.

function Install-DevPilot {
  $ErrorActionPreference = 'Stop'
  $tag      = '__TAG__'
  $url      = '__URL__'
  $expected = '__SHA256__'
  $tmp      = $null
  try {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'DevPilot needs 64-bit Windows 10 or 11.' }

    Write-Host "DevPilot $tag" -ForegroundColor Cyan
    $tmp = Join-Path $env:TEMP ('devpilot-setup-' + [guid]::NewGuid().ToString('N') + '.exe')

    Write-Host 'Downloading the installer (about 180 MB)...'
    $old = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'   # the progress bar makes Windows PowerShell 5.1 very slow
    try { Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing } finally { $ProgressPreference = $old }

    Write-Host 'Checking the file...'
    $actual = (Get-FileHash -Algorithm SHA256 -Path $tmp).Hash.ToLower()
    if ($actual -ne $expected.ToLower()) {
      throw "The downloaded file does not match the expected checksum, so it was not run.`n  expected $expected`n  got      $actual"
    }

    Write-Host 'Installing for your user (this takes a minute)...'
    $p = Start-Process -FilePath $tmp -ArgumentList '/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "The installer stopped with code $($p.ExitCode)." }

    $exe = Join-Path $env:LOCALAPPDATA 'Programs\DevPilot\devpilot.exe'
    if (-not (Test-Path $exe)) { throw "DevPilot was not found at $exe after installing." }
    Write-Host 'DevPilot is installed.' -ForegroundColor Green

    # DevPilot opens labs in VS Code and checks them with Python and Git, so say what is missing
    $py = (Get-Command python -ErrorAction SilentlyContinue) -or (Get-Command py -ErrorAction SilentlyContinue)
    foreach ($t in @(
      @{ Name = 'Visual Studio Code'; Ok = [bool](Get-Command code -ErrorAction SilentlyContinue); Hint = 'https://code.visualstudio.com' },
      @{ Name = 'Python 3.10 or newer'; Ok = [bool]$py; Hint = 'https://www.python.org/downloads (tick "Add python.exe to PATH")' },
      @{ Name = 'Git'; Ok = [bool](Get-Command git -ErrorAction SilentlyContinue); Hint = 'https://git-scm.com' })) {
      if (-not $t.Ok) { Write-Host ("Not found: {0}. Install it from {1}" -f $t.Name, $t.Hint) -ForegroundColor Yellow }
    }

    if (-not $env:DEVPILOT_NO_LAUNCH) { Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) }
    $global:LASTEXITCODE = 0
  } catch {
    Write-Host ''
    Write-Host ('DevPilot was not installed: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Other ways to install: https://devpilot.web.app/docs/install-windows'
    $global:LASTEXITCODE = 1
  } finally {
    if ($tmp -and (Test-Path $tmp)) { Remove-Item -Force $tmp -ErrorAction SilentlyContinue }
  }
}

Install-DevPilot
