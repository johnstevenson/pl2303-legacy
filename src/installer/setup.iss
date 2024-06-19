; a config.iss file is required
#ifndef Config
  #ifexist "config.iss"
    #include "config.iss"
  #endif
#endif

#ifndef Release
  #define BaseFilename StringChange(AppName, " ", "")
  #define OutputDir "..\..\builds\output\"
  #define OutputBaseFilename BaseFilename + "Setup"
  #define AppExeName BaseFilename + ".exe"
  #define AppExeSrc OutputDir + AppExeName
#endif

[Setup]
AppId={{EDA77891-8FDB-44FD-AD73-622FF79CCFF7}
AppName={#AppName}
AppVersion={#AppVersion}

; compile directives
Compression=lzma
SolidCompression=yes

; runtime directives
PrivilegesRequired=admin
ArchitecturesAllowed=x64os or x86os
ArchitecturesInstallIn64BitMode=x64os
MinVersion=10.0.19041
DisableWelcomePage=yes
DisableProgramGroupPage=yes
DefaultDirName={autopf}\{#AppName}
SetupLogging=yes

; cosmetic
WizardStyle=modern
WizardSizePercent=110,100

; uninstaller
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

; output
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}

[LangOptions]
DialogFontSize=10

[Files]
Source: "{#AppExeSrc}"; DestDir: "{app}"; DestName: "{#AppExeName}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram, {#AppName}}"; Flags: unchecked nowait postinstall runascurrentuser skipifsilent

[Messages]
SetupAppTitle=Setup - {#AppName}
SetupWindowTitle=Setup - {#AppName} {#AppVersion}

#include "..\shared\escape.iss"
#include "..\shared\common.iss"
#include "userdrivers.iss"

[Code]
type
  TStartPage = record
    ID     : Integer;
    Info   : TNewStaticText;
  end;

var
  GAppExe: String;
  GStartPage: TStartPage;

const
  APP_NAME = '{#AppName}';
  APP_EXE_NAME = '{#AppExeName}';

function GetBase(Control: TWinControl): Integer; forward;
function StartPageCreate(Id: Integer; Caption, Description: String): TWizardPage; forward;
procedure StartPageRunClick(Sender: TObject); forward;

function InitializeSetup(): Boolean;
var
  TmpDir: String;

begin

  Result := True;
  TmpDir := ExpandConstant('{tmp}');
  GAppExe := TmpDir + '\' + APP_EXE_NAME;
  ExtractTemporaryFile(APP_EXE_NAME);

end;

procedure InitializeWizard;
var
  S: String;

begin

  ThemeInit();

  S := 'Choose whether to run the program before you install it.';
  StartPageCreate(wpWelcome, 'Options', S);

end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  Confirm := CurPageID <> GStartPage.ID;
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  InitCommon();
end;

procedure InitializeUninstallProgressForm();
begin
  ThemeInit();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin

  if CurUninstallStep = usUninstall then
    UserDriversDelete;

end;

function GetBase(Control: TWinControl): Integer;
begin
  Result := Control.Top + Control.Height;
end;

function StartPageCreate(Id: Integer; Caption, Description: String): TWizardPage;
var
  S: String;
  Base: Integer;
  Text: TNewStaticText;
  RunButton: TNewButton;

begin

  Result := CreateCustomPage(Id, Caption, Description);
  GStartPage.ID := Result.ID;

  Text := TNewStaticText.Create(Result);
  S := Format('Before Setup installs %s on your computer,', [APP_NAME]);
  S := S + ' you can check if the program works with your device.';
  S := S + ' Click Run Program to do this, or Next to continue.';

  with Text do
  begin
    Parent := Result.Surface;
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop, akRight];
    AutoSize := True;
    WordWrap := True;
    Caption := S;
  end;

  Base := GetBase(Text);
  RunButton := TNewButton.Create(Result);

  with RunButton do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(26);
    Caption := 'Run Program';
    Width := WizardForm.CalculateButtonWidth([Caption]);
    Height := ScaleY(23);
    OnClick := @StartPageRunClick;
  end;

  GStartPage.Info := TNewStaticText.Create(Result);
  S := Format('Click Next to install %s, or Cancel to exit.', [APP_NAME]);

  with GStartPage.Info do
  begin
    Parent := Result.Surface;
    Top := Result.SurfaceHeight - ScaleY(24);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akBottom, akRight];
    AutoSize := True;
    Caption := S;
    Visible := False;
  end;

end;

procedure StartPageRunClick(Sender: TObject);
var
  ExitCode: Integer;

begin

  Exec(GAppExe, '', '', SW_SHOW, ewWaitUntilTerminated, ExitCode);
  GStartPage.Info.Visible := True;

end;
