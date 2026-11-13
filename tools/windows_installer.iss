; DevPilot for Windows: one installer that puts the app in your user folder (no administrator rights needed), adds a Start
; menu entry and an uninstaller. Built by tools/build_windows.ps1 with Inno Setup 6:
;   ISCC.exe /DAppVersion=0.1.0 /DSourceDir=<path to release\devpilot> tools\windows_installer.iss
; Your progress (the .devpilot and DevPilotLabs folders in your profile) is NOT removed when you uninstall.
#define AppName "DevPilot"
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\release\devpilot"
#endif

[Setup]
AppId={{6F6B0B5E-3A1D-4C57-9B8E-5D2F7A1C9E41}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=DevPilot
AppPublisherURL=https://devpilot.web.app
AppSupportURL=https://devpilot.web.app/docs/troubleshooting
AppUpdatesURL=https://github.com/Error404NotFoundSoftwareSolutions/devpilot-releases/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\DevPilot
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\release
OutputBaseFilename=devpilot-windows-x64-setup
SetupIconFile=..\apps\desktop\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\devpilot.exe
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\DevPilot"; Filename: "{app}\devpilot.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\DevPilot"; Filename: "{app}\devpilot.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\devpilot.exe"; Description: "Start DevPilot"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent
