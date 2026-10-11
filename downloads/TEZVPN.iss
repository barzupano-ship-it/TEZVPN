[Setup]
AppId={{A7B3E1C4-9D20-4F6A-8C11-1A2B3C4D5E6F}
AppName=TEZVPN
AppVersion=1.0.5
AppPublisher=TEZVPN
DefaultDirName={localappdata}\TEZVPN
DefaultGroupName=TEZVPN
DisableProgramGroupPage=yes
OutputDir=D:\TEZ VPN APP\downloads
OutputBaseFilename=TEZVPN-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\TEZVPN.exe
SetupIconFile=D:\TEZ VPN APP\flutter\windows\runner\resources\app_icon.ico

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\TEZVPN"; Filename: "{app}\TEZVPN.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\TEZVPN.exe"; WorkingDir: "{app}"; Description: "Открыть TEZVPN"; Flags: nowait postinstall skipifsilent
