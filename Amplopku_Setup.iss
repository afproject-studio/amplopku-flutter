[Setup]
AppName=Amplopku
AppVersion=1.0
DefaultDirName={autopf}\Amplopku
DefaultGroupName=Amplopku
OutputDir=Output
OutputBaseFilename=Amplopku_Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "D:\amplopku_fixed\amplopku\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Amplopku"; Filename: "{app}\amplopku.exe"
Name: "{commondesktop}\Amplopku"; Filename: "{app}\amplopku.exe"

[Run]
Filename: "{app}\amplopku.exe"; Description: "Jalankan Amplopku"; Flags: nowait postinstall skipifsilent