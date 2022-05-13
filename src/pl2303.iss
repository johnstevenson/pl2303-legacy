#ifndef SetupVersion
  #include "version.iss"
#endif

; allow additional configuration
#ifexist "config.iss"
  #include "config.iss"
#endif

#ifndef AppName
  #define AppName "PL2303 Legacy"
#endif

#define AppFileName = StringChange(AppName, " ", "-")
#define UpdaterExe "updater.exe"

[Setup]
AppName={#AppName}
AppVersion={#SetupVersion}

; compile directives
Compression=lzma
SolidCompression=yes

; runtime directives
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.18362
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
DisableProgramGroupPage=yes
CreateAppDir=no

; uninstall
Uninstallable=no

; cosmetic
WizardStyle=modern
WizardSizePercent=110,100

; settings for release or dev compilations
#ifdef Release
  #include "build.iss";
#else
  OutputDir=..\builds\output
  OutputBaseFilename={#AppFileName}.dev
#endif

[LangOptions]
DialogFontSize=10

[Files]
Source: updater\bin\Release\{#UpdaterExe}; Flags: dontcopy;

[Messages]
SetupAppTitle={#AppName}
SetupWindowTitle={#AppName}
FinishedHeadingLabel=[name] has completed
FinishedLabelNoIcons=Run this progam again if your driver has changed.
ClickFinish=Click Finish to exit.

[Code]
type
  TDriverRec = record
    OemInf        : String;
    OriginalInf   : String;
    Version       : String;
    PackedVersion : Int64;
    Date          : String;
    DisplayName   : String;
    Exists        : Boolean;
  end;

  TLegacyDrivers = Array[0..1] of TDriverRec;

  TPLDrivers = record
    Count     : Integer;
    Items     : Array of TDriverRec;
  end;

  TDeviceRec = record
    Description : String;
    ErrorMsg    : String;
    Recognized  : Boolean;
    Driver      : TDriverRec;
  end;

  TConfigRec = record
    Drivers     : TPLDrivers;         {drivers from connected device}
    LegacyStore : TPLDrivers;         {legacy drivers installed in driver store}
    Packages    : TLegacyDrivers;     {legacy driver packages for installation}
    Device      : TDeviceRec;         {the connected device}
  end;

  TUpdateRec = record
    Driver      : TDriverRec;
    Status      : Integer;
    Message     : String;
  end;

  TFlagsRec = record
    MinDriver   : Int64;
    CIParam     : Boolean;
    LastDriver  : TDriverRec;
  end;

  TCustomPages = record
    Start     : TWizardPage;
    Progress  : TOutputProgressWizardPage;
    Finish    : TWizardPage;
  end;

  TStartPage = record
    Current     : TNewCheckListBox;
    Drivers     : TNewCheckListBox;
  end;

  TFinishPage = record
    Current     : TNewCheckListBox;
    InfoHeader  : TNewStaticText;
    Info        : TNewStaticText;
    SaveButton  : TNewButton;
  end;

var
  GCmdExe: String;                  {full pathname to system cmd}
  GPnpExe: String;                  {full pathname to system pnputil}
  GUpdaterExe: String;              {full pathname to installer updater}
  GConfig: TConfigRec;              {contains driver and status data}
  GUpdate: TUpdateRec;              {contains data from the update}
  GFlags: TFlagsRec;                {contains runtime flags}
  GTmpDir: String;                  {the temp directory that Inno uses}
  GStdOut: String;                  {the temp file used to capture stdout}
  GExportDir: String;               {folder to export to in temp directory}
  GPages: TCustomPages;             {group of custom pages}
  GStartPage: TStartPage;           {contains Start page controls}
  GFinishPage: TFinishPage;         {contains Finish page controls}

const
  LF = #13#10;
  LF2 = LF + LF;

  APP_NAME = '{#AppName}';
  ACTION_INSTALL = 1;
  ACTION_UNINSTALL = 2;

  DRIVER_INF = 'ser2pl.inf';
  LEGACY_HXA = '3.3.11.152';
  LEGACY_TA = '3.8.36.2';
  MIN_DRIVER = '3.8.36.0';

  PORTSCLASS = '{4d36e978-e325-11ce-bfc1-08002be10318}';
  UPDATER_EXE = '{#UpdaterExe}';

  UPDATE_SUCCESS = 0;
  UPDATE_ERROR = 100;
  UPDATE_UNRECOGNIZED = 200;

{Init functions}
function ConfigInit(var Config: TConfigRec): Boolean; forward;
function GetLegacyPackage(DriverPath, Folder: String; var Exists, Error: Boolean): TDriverRec; forward;
procedure ThemeInit; forward;

{Config functions}
procedure ConfigUpdate(var Config: TConfigRec); forward;
function GetPLDrivers(var Device: TDeviceRec): TPLDrivers; forward;
function GetPLInstance(PnpOutput: TArrayOfString): TArrayOfString; forward;
function GetPLInstanceData(Instance: TArrayOfString; var Device: TDeviceRec): TArrayOfString; forward;
function GetPLMatchingDrivers(Drivers: TArrayOfString; var Device: TDeviceRec): TPLDrivers; forward;
procedure ItemizeDrivers(Drivers: TPLDrivers; Matched: Boolean; var Config: TConfigRec); forward;
procedure SortDrivers(var Drivers: TPLDrivers); forward;

{Driver update functions}
procedure DriverUpdate(var Config: TConfigRec); forward;
procedure DriverUpdateRun(Driver: TDriverRec; var Config: TConfigRec); forward;
function InstallDriver(Driver: TDriverRec; var Config: TConfigRec): Boolean; forward;
procedure RemoveLegacyDrivers(Config: TConfigRec); forward;
procedure SetUpdateRec(Config: TConfigRec; Driver: TDriverRec; Status: Integer; SameDriver: Boolean); forward;
function TestChip(Driver: TDriverRec; var Config: TConfigRec; var TestDevice: TDeviceRec): Boolean; forward;

{Device functions}
procedure DebugUnrecognizedDevice(Device: TDeviceRec); forward;
function DeviceError(Device: TDeviceRec; Error: String): Boolean; forward;
procedure InitDeviceRec(var Rec: TDeviceRec); forward;
function NoDevice(Config: TConfigRec): Boolean; forward;
procedure SetDeviceDescription(var Device: TDeviceRec); forward;
procedure SetDeviceValidity(var Device: TDeviceRec); forward;

{Driver utility functions}
procedure AddToDriverList(Rec: TDriverRec; var Drivers: TPLDrivers); forward;
procedure ClearDriverList(var Drivers: TPLDrivers); forward;
function CompareVersion(Driver1, Driver2: TDriverRec): Integer; forward;
procedure DebugDriver(Message: String; Driver: TDriverRec); forward;
procedure DebugPLDrivers(Drivers: TPLDrivers); forward;
function FormatDriverDateAndVersion(Driver: TDriverRec; ForDisplay: Boolean): String; forward;
function GetDriverDateAndVersion(Data: String; var DriverRec: TDriverRec): Boolean; forward;
procedure InitDriverRec(var Rec: TDriverRec); forward;
function IsDisplayedDriver(Driver1, Driver2: TDriverRec): Boolean; forward;
function IsSameVersion(Driver1, Driver2: TDriverRec): Boolean; forward;

{Exec functions}
function ExecPnp(Params: String): Boolean; forward;
function ExecPnpDeleteDriver(Driver: TDriverRec): Boolean; forward;
function ExecPnpExportDriver(Driver: TDriverRec; var OriginalInf: String): Boolean; forward;
function ExecPnpEnumDevices(var Output: TArrayOfString): Boolean; forward;
function ExecSaveProgram(Path: String): Boolean; forward;
function ExecUpdater(InfPath: String): Boolean; forward;

{Common functions}
procedure AddLine(var Existing: String; Value: String); forward;
procedure AddPara(var Existing: String; Value: String); forward;
procedure AddParam(var Params: String; Value: String); forward;
procedure AddStr(var Existing: String; Value: String); forward;
procedure Debug(Message: String); forward;
procedure DebugExecBegin(Exe, Params: String); forward;
procedure DebugExecEnd(Res: Boolean; ExitCode: Integer); forward;
procedure DebugPageName(Id: Integer); forward;
function IsEmpty(const Value: String): Boolean; forward;
function NotEmpty(const Value: String): Boolean; forward;
procedure ShowErrorMessage(Message: String); forward;
function SplitString(Value, Separator: String): TArrayOfString; forward;

{Custom page functions}
function FinishPageCreate(Id: Integer; Caption, Description: String): TWizardPage; forward;
procedure FinishPageUpdate(Config: TConfigRec; Update: TUpdateRec); forward;
procedure FinishPageSaveClick(Sender: TObject); forward;
procedure ProgressPageShow(Driver: TDriverRec); forward;
function StartPageCreate(Id: Integer; Caption, Description: String): TWizardPage; forward;
procedure StartPageScanClick(Sender: TObject); forward;
procedure StartPageScanUpdate; forward;
procedure StartPageUpdate(Config: TConfigRec); forward;

{Custom page utility functions}
procedure CreateCurrentDriver(Page: TWizardPage); forward;
function GetBase(Control: TWinControl): Integer; forward;
procedure SetCurrentDriver(Page: TWizardPage; Config: TConfigRec); forward;

#include "escape.iss"

function InitializeSetup(): Boolean;
var
  S: String;

begin

  GCmdExe := ExpandConstant('{cmd}');
  GPnpExe := ExpandConstant('{sys}') + '\pnputil.exe';
  GTmpDir := ExpandConstant('{tmp}');
  GExportDir := GTmpDir + '\export';
  GStdOut := GTmpDir + '\stdout.txt';
  GUpdaterExe := GTmpDir + '\' + UPDATER_EXE;

  {Extract our temp files to installer directory}
  #ifdef DriverPath
    ExtractTemporaryFiles('drivers\*');
  #endif
  ExtractTemporaryFile(UPDATER_EXE);

  {Create export dir in temp directory}
  CreateDir(GExportDir);

  {Set flags, must be before ConfigInit}
  StrToVersion(MIN_DRIVER, GFlags.MinDriver);
  GFlags.CIParam := NotEmpty(ExpandConstant('{param:CI}'));

  Result := ConfigInit(GConfig);

  if not Result then
  begin
    S := Format('Unable to start %s.', [APP_NAME]);
    AddPara(S, 'Package configuration error.');
    ShowErrorMessage(S);
  end;

end;

procedure InitializeWizard;
var S: String;

begin

  ThemeInit();

  S := 'For older devices that use unsupported Prolific microchips.';
  AddStr(S, ' If the current driver is not shown below, connect your device and click Scan Drivers.');

  GPages.Start := StartPageCreate(wpWelcome, 'PL2303 legacy USB-to-Serial drivers', S);

  GPages.Finish := FinishPageCreate(GPages.Start.ID,
    'Driver update result', '');

  GPages.Progress := CreateOutputProgressPage('', '');

end;

procedure CurPageChanged(CurPageID: Integer);
begin

  if CurPageID = GPages.Start.ID then
  begin

    {We must check Pages.Progress.Tag first}
    if CurPageID = GPages.Progress.Tag then
      GPages.Progress.Tag := 0
    else
      StartPageScanUpdate();

  end
  else if CurPageID = GPages.Finish.ID then
    FinishPageUpdate(GConfig, GUpdate);
  {
  if CurPageID = GPages.Finish.ID then
  begin
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish);
    WizardForm.CancelButton.Visible := False;
  end
  else
  begin
    WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);
    WizardForm.CancelButton.Visible := True;
  end;
  }
  DebugPageName(CurPageID);

end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin

  Result := True;

  if CurPageID = GPages.Start.ID then
    DriverUpdate(GConfig);

end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin

  {Remove cancel confirmation}
  Debug('User cancelled Setup');
  Confirm := False;

end;


{*************** Init functions ***************}

function ConfigInit(var Config: TConfigRec): Boolean;
var
  Package: TDriverRec;
  DriverPath: String;
  Exists: Boolean;
  Error: Boolean;

begin

  Result := False;
  DriverPath := GTmpDir + '\drivers';

  {Legacy HXA}
  Package := GetLegacyPackage(DriverPath, LEGACY_HXA, Exists, Error);
  DebugDriver('Registering legacy HXA package', Package);

  if Error then
  begin
    Debug('Error in legacy HXA package');
    Exit;
  end;

  Package.DisplayName := 'Legacy PL2303 HXA';
  Package.Exists := Exists;
  Config.Packages[0] := Package;

  {Legacy TA/TB}
  Package := GetLegacyPackage(DriverPath, LEGACY_TA, Exists, Error);
  DebugDriver('Registering legacy TA package', Package);

  if Error then
  begin
    Debug('Error in legacy TA package');
    Exit;
  end;

  Package.DisplayName := 'Legacy PL2303 TA';
  Package.Exists := Exists;
  Config.Packages[1] := Package;

  if Config.Packages[0].Exists <> Config.Packages[1].Exists then
  begin
    Debug('Legacy packages misconfiguration');
    Exit;
  end;

  Result := True;

end;

function GetLegacyPackage(DriverPath, Folder: String; var Exists, Error: Boolean): TDriverRec;
var
  OriginalInf: String;
  IniValue: String;

begin

  IniValue := '';
  OriginalInf := DriverPath + '\' + Folder + '\' + DRIVER_INF;
  Exists := FileExists(OriginalInf);
  Error := False;

  if Exists then
  begin
    IniValue := GetIniString('version', 'DriverVer', '', OriginalInf);
    Result.OriginalInf := OriginalInf;
  end;

  if not GetDriverDateAndVersion(IniValue, Result) then
    Error := Exists;

end;


{Sets the font color to dark grey}
procedure ThemeInit();
var
  Color: Integer;

begin

  {Hex 303030}
  Color := (48 shl 16) + (48 shl 8) + 48;
  WizardForm.Font.Color := Color;

end;


{*************** Config functions ***************}

procedure ConfigUpdate(var Config: TConfigRec);
var
  Device: TDeviceRec;
  Drivers: TPLDrivers;
  Driver: TDriverRec;
  Matched: Boolean;

begin

  ClearDriverList(Config.Drivers);
  ClearDriverList(Config.LegacyStore);
  InitDeviceRec(Device);

  Drivers := GetPLDrivers(Device);
  Config.Device := Device;
  Matched := False;

  {Add LegaxyHXA}
  Driver := Config.Packages[0];

  if IsSameVersion(Device.Driver, Driver) then
  begin
    Matched := True;
    AddStr(Driver.DisplayName, ' (current driver)');
  end;

  AddToDriverList(Driver, Config.Drivers);

  {Add LegaxyTA/TB}
  Driver := Config.Packages[1];

  if not Matched and IsSameVersion(Device.Driver, Driver) then
  begin
    Matched := True;
    AddStr(Driver.DisplayName, ' (current driver)');
  end;

  AddToDriverList(Driver, Config.Drivers);

  {Add sorted drivers and legacy store}
  ItemizeDrivers(Drivers, Matched, Config);

end;

function GetPLDrivers(var Device: TDeviceRec): TPLDrivers;
var
  Output: TArrayOfString;
  Instance: TArrayOfString;
  Drivers: TArrayOfString;

begin

  Debug('Seaching for connected PL2303 device');

  if not ExecPnpEnumDevices(Output) then
    Exit;

  Instance := GetPLInstance(Output);
  Drivers := GetPLInstanceData(Instance, Device);
  SetDeviceDescription(Device);
  SetDeviceValidity(Device);
  Result := GetPLMatchingDrivers(Drivers, Device);

  DebugPLDrivers(Result);

end;

function GetPLInstance(PnpOutput: TArrayOfString): TArrayOfString;
var
  Count: Integer;
  InstanceCount: Integer;
  Index: Integer;
  I: Integer;
  Skip: Boolean;
  Line: String;

begin

  Count := GetArrayLength(PnpOutput);
  SetArrayLength(Result, Count);
  InstanceCount := 0;
  Index := 0;
  Skip := True;

  for I := 0 to Count - 1 do
  begin
    Line := Trim(PnpOutput[I]);

    if Pos('Instance ID:', Line) = 1 then
    begin

      if Pos('USB\VID_067B&PID_2303', Uppercase(Line)) = 0 then
        Skip := True
      else
      begin
        Skip := False;
        Inc(InstanceCount);

        if InstanceCount > 1 then
        begin
          // Not really sure what to do here other than log it
          Debug('More than one device is connected');
          Break;
        end;
      end;

    end;

    if not Skip then
    begin
      Result[Index] := Line;
      Inc(Index);
    end;

  end;

  SetArrayLength(Result, Index);

end;

function GetPLInstanceData(Instance: TArrayOfString; var Device: TDeviceRec): TArrayOfString;
var
  Count: Integer;
  I: Integer;
  Line: String;
  Index: Integer;
  Start: Integer;
  Description: String;
  Name: String;

begin

  Count := GetArrayLength(Instance);
  SetArrayLength(Result, Count);

  Description := 'Device Description:';
  Name := 'Driver Name:';

  // Parse out device data up to Matching Drivers key
  for I := 0 to Count - 1 do
  begin
    Index := I;
    Line := Trim(Instance[I]);

    if Pos(Description, Line) = 1 then
    begin
      Start := Length(Description) + 1;
      Device.Description := Trim(Copy(Line, Start, MaxInt));
      Continue;
    end;

    if Pos(Name, Line) = 1 then
    begin
      Start := Length(Name) + 1;
      Device.Driver.OemInf := Trim(Copy(Line, Start, MaxInt));
      Continue;
    end;

    if Pos('Matching Drivers:', Line) = 1 then
    begin
      Inc(Index);
      Break;
    end;

  end;

  Start := Index;
  Index := 0;

  // Add Matching Drivers lines
  for I := Start to Count - 1 do
  begin
    Result[Index] := Trim(Instance[I]);
    Inc(Index);
  end;

  SetArrayLength(Result, Index);

end;

function GetPLMatchingDrivers(Drivers: TArrayOfString; var Device: TDeviceRec): TPLDrivers;
var
  Count: Integer;
  I: Integer;
  Values: TArrayOfString;
  Key: String;
  Value: String;
  ExpectedKey: String;
  DriverRec: TDriverRec;

begin

  Count := GetArrayLength(Drivers);
  DriverRec.Exists := True;
  ExpectedKey := 'Driver Name';

  for I := 0 to Count - 1 do
  begin
    Values := SplitString(Trim(Drivers[I]), ':');

    if GetArrayLength(Values) <> 2 then
      Continue;

    Key := Trim(Values[0]);
    Value := Trim(Values[1]);

    if Key <> ExpectedKey then
      Continue;

    if Key = 'Driver Name' then
    begin
      DriverRec.OemInf := Value;
      ExpectedKey := 'Original Name';
      Continue;
    end;

    if Key = 'Original Name' then
    begin
      DriverRec.OriginalInf := Value;
      ExpectedKey := 'Driver Version';
      Continue;
    end;

    if Key = 'Driver Version' then
    begin
      GetDriverDateAndVersion(Value, DriverRec);
      AddToDriverList(DriverRec, Result);

      // See if this is the installed driver
      if DriverRec.OemInf = Device.Driver.OemInf then
        Device.Driver := DriverRec;

      ExpectedKey := 'Driver Name';
    end;
  end;

end;

procedure ItemizeDrivers(Drivers: TPLDrivers; Matched: Boolean; var Config: TConfigRec);
var
  TmpDrivers: TPLDrivers;
  I: Integer;
  Driver: TDriverRec;

begin

  for I := 0 to Drivers.Count - 1 do
  begin
    Driver := Drivers.Items[I];
    Driver.DisplayName := 'Prolific';

    if IsSameVersion(Config.Device.Driver, Driver) then
    begin
      if not Matched then
      begin
        Matched := True;
        AddStr(Driver.DisplayName, ' (current driver)');

        {Add to main drivers}
        AddToDriverList(Driver, Config.Drivers);

        Continue;
      end;
    end;

    {Add installed legacy drivers to LegacyStore}
    if IsSameVersion(Config.Packages[0], Driver) then
    begin
      AddToDriverList(Driver, Config.LegacyStore);
      Continue;
    end;

    if IsSameVersion(Config.Packages[1], Driver) then
    begin
      AddToDriverList(Driver, Config.LegacyStore);
      Continue;
    end;

    {Add to tmp drivers if not a legacy driver}
    AddToDriverList(Driver, TmpDrivers);

  end;

  SortDrivers(TmpDrivers);

  {Add sorted tmp drivers to main drivers}
  for I := 0 to TmpDrivers.Count - 1 do
    AddToDriverList(TmpDrivers.Items[I], Config.Drivers);

end;


procedure SortDrivers(var Drivers: TPLDrivers);
var
  Tmp: TDriverRec;
  Changed: Boolean;
  I: Integer;

begin

  Changed := True;

  while Changed do
  begin
    Changed := False;

    for I := 0 to Drivers.Count - 2 do
    begin

      if (CompareVersion(Drivers.Items[I], Drivers.Items[I + 1]) > 0) then
      begin
        Tmp := Drivers.Items[I + 1];
        Drivers.Items[I + 1] := Drivers.Items[I];
        Drivers.Items[I] := Tmp;
        Changed := True;
      end;

    end;
  end;

end;


{*************** Driver update functions ***************}

procedure DriverUpdate(var Config: TConfigRec);
var
  Index: Integer;
  Driver: TDriverRec;

begin

  {See if we have a driver selected}
  Index := GStartPage.Drivers.ItemIndex;

  if Index <> -1 then
    Driver := Config.Drivers.Items[Index];

  GFlags.LastDriver := Driver;

  {Note that we cannot use NoDevice here because the user may
  have connected and not scanned, or Windows may have found
  and installed the latest driver}
  if not Driver.Exists then
  begin

    {Skip update if not CI}
    if GFlags.CIParam then
      Debug('Driver not selected, using empty driver')
    else
    begin
      Debug('Skipping update, driver not selected');
      SetUpdateRec(Config, Driver, UPDATE_ERROR, False);
      Exit;
    end;

  end;

  GPages.Progress.Tag := WizardForm.CurPageID;
  ProgressPageShow(Driver);

  try
    DriverUpdateRun(Driver, Config);
    GPages.Progress.SetProgress(1000, 1000);
  finally
    GPages.Progress.Hide();
  end;

end;

procedure DriverUpdateRun(Driver: TDriverRec; var Config: TConfigRec);
var
  SameDriver: Boolean;
  TestDevice: TDeviceRec;

begin

  SameDriver := IsSameVersion(Driver, Config.Device.Driver);

  if not TestChip(Driver, Config, TestDevice) then
  begin
    SetUpdateRec(Config, Driver, UPDATE_ERROR, SameDriver);
    Exit;
  end;

  if not TestDevice.Recognized then
  begin
    {Config will have been updated}
    DebugUnrecognizedDevice(TestDevice);
    SetUpdateRec(Config, Driver, UPDATE_UNRECOGNIZED, SameDriver);
    Exit;
  end;

  if not SameDriver then
  begin

    {Install driver and update config}
    if not InstallDriver(Driver, Config) then
    begin
      SetUpdateRec(Config, Driver, UPDATE_ERROR, SameDriver);
      Exit;
    end;

    if not Config.Device.Recognized then
    begin
      DebugUnrecognizedDevice(Config.Device);
      SetUpdateRec(Config, Driver, UPDATE_UNRECOGNIZED, SameDriver);
      Exit;
    end;

  end;

  RemoveLegacyDrivers(Config);
  SetUpdateRec(Config, Driver, UPDATE_SUCCESS, SameDriver);

end;

function InstallDriver(Driver: TDriverRec; var Config: TConfigRec): Boolean;
var
  InfPath: String;

begin

  Result := False;
  DebugDriver('Installing driver', Driver);

  if IsEmpty(Driver.OemInf) then
    InfPath := Driver.OriginalInf
  else
  begin

    {We need to export the driver to the temp dir}
    if not ExecPnpExportDriver(Driver, InfPath) then
      Exit;
  end;

  if not ExecUpdater(InfPath) then
  begin
    DebugDriver('Failed to install driver', Driver);
    Exit;
  end;

  ConfigUpdate(Config);

  if not IsSameVersion(Driver, Config.Device.Driver) then
    DebugDriver('Failed to install driver', Driver)
  else
  begin
    DebugDriver('Successfully installed driver', Driver);
    Result := True;
  end;

end;

procedure RemoveLegacyDrivers(Config: TConfigRec);
var
  I: Integer;
  LegacyDriver: TDriverRec;

begin

  for I := 0 to Config.LegacyStore.Count - 1 do
  begin
    LegacyDriver := Config.LegacyStore.Items[I];

    if IsSameVersion(LegacyDriver, Config.Device.Driver) then
      Continue;

    DebugDriver('Removing legacy driver', LegacyDriver);

    if not ExecPnpDeleteDriver(LegacyDriver) then
      DebugDriver('Failed to remove legacy driver', LegacyDriver)
    else
      DebugDriver('Successfully removed legacy driver', LegacyDriver);

  end;

end;

procedure SetUpdateRec(Config: TConfigRec; Driver: TDriverRec; Status: Integer; SameDriver: Boolean);
begin

  GUpdate.Driver := Driver;
  GUpdate.Status := Status;

  if Status <> UPDATE_SUCCESS then
  begin

    if NoDevice(Config) then
      GUpdate.Message := 'Error: Not connected.'
    else
    begin

      if Driver.Exists then
        GUpdate.Message := 'Error: Unable to install the selected driver.'
      else
        GUpdate.Message := 'Error: No driver selected.';

    end;

  end
  else
  begin

    if SameDriver then
      GUpdate.Message := 'Success: Driver already installed.'
    else
      GUpdate.Message := 'Success: The selected driver has been installed.';

  end;

end;

function TestChip(Driver: TDriverRec; var Config: TConfigRec; var TestDevice: TDeviceRec): Boolean;
var
  CurrentDriver: TDriverRec;
  TestConfig: TConfigRec;
  TestDriver: TDriverRec;
  PackedVersion: Int64;
  I: Integer;

begin

  {Result is false only if an operation has failed}
  Result := True;

  CurrentDriver := Config.Device.Driver;
  TestDevice := Config.Device;

  if not TestDevice.Recognized then
    Exit;

  {Return if the current driver is one that reports unrecognized chips}
  if ComparePackedVersion(CurrentDriver.PackedVersion, GFlags.MinDriver) >= 0 then
  begin
    DebugDriver('Current driver reports unrecognized chips', CurrentDriver);
    Exit;
  end;

  DebugDriver('Current driver does not report unrecognized chips', CurrentDriver);

  {Return if we are installing a driver that reports unrecognized chips}
  if ComparePackedVersion(Driver.PackedVersion, GFlags.MinDriver) >= 0 then
  begin
    DebugDriver('Selected driver reports unrecognized chips', Driver);
    Exit;
  end;

  DebugDriver('Selected driver does not report unrecognized chips', Driver);

  {Find the most recent driver to test}
  TestDriver := Config.Packages[0];
  PackedVersion := Config.Packages[0].PackedVersion;

  {Legacy drivers are listed first, so start from Legacy TAB}
  for I := 1 to Config.Drivers.Count -1 do
  begin

    if ComparePackedVersion(Config.Drivers.Items[I].PackedVersion, PackedVersion) > 0 then
    begin
      PackedVersion := Config.Drivers.Items[I].PackedVersion;
      TestDriver := Config.Drivers.Items[I];
    end;

  end;

  {Note that if we have an empty driver, installation will fail}
  if not InstallDriver(TestDriver, TestConfig) then
  begin
    Result := False;
    Exit;
  end;

  TestDevice := TestConfig.Device;

  {If not recognized set config to the test config results
  so that this is shown on the finish page}
  if not TestDevice.Recognized then
  begin
    Config := TestConfig;
    Exit;
  end;

  {Put everything back if the driver is the same as the
  current driver as this doesn't get installed}
  if IsSameVersion(Driver, CurrentDriver) then
  begin

    if not InstallDriver(CurrentDriver, TestConfig) then
    begin
      Result := False;
      Exit;
    end;

  end;

end;


{*************** Device functions ***************}

procedure DebugUnrecognizedDevice(Device: TDeviceRec);
var
  Msg: String;

begin

  Msg := Format('Device not recognized: %s. Driver', [Device.Description]);
  DebugDriver(Msg, Device.Driver);

end;

function DeviceError(Device: TDeviceRec; Error: String): Boolean;
var
  Parts: TArrayOfString;
  Count: Integer;
  I: Integer;

begin

  Result := False;

  if IsEmpty(Device.ErrorMsg) then
    Exit;

  Parts := SplitString(Error, '/');
  Count := GetArrayLength(Parts);

  for I := 0 to Count - 1 do
  begin

    if Device.ErrorMsg = Parts[I] then
    begin
      Result := True;
      Break;
    end;

  end;

end;

procedure InitDeviceRec(var Rec: TDeviceRec);
begin

  Rec.Description := '';
  Rec.ErrorMsg := '';
  Rec.Recognized := False;

  InitDriverRec(Rec.Driver);
  GetDriverDateAndVersion('', Rec.Driver);

end;

procedure SetDeviceDescription(var Device: TDeviceRec);
var
  Value: String;
  Phrases: Array[0..3] of String;
  I: Integer;
  Index: Integer;
  LastChar: String;

begin

  if IsEmpty(Device.Description) then
    Exit;

  Value := Uppercase(Device.Description);

  Phrases[0] := 'PLEASE CONTACT YOUR SUPPLIER';
  Phrases[1] := 'CONTACT YOUR SUPPLIER';
  Phrases[2] := 'PLEASE CONTACT';
  Phrases[3] := 'CONTACT';

  for I := Low(Phrases) to High(Phrases) do
  begin
    Index := Pos(Phrases[I], Value);

    if Index <> 0 then
      Break;
  end;

  if Index = 0 then
    Exit;

  Value := Trim(Copy(Device.Description, 1, Index - 1));
  Index := Length(Value);
  LastChar := Value[Index];

  if (LastChar = '.') or (LastChar = ',') then
    Delete(Value, Index, 1);

  Device.Description := Value;
  Device.ErrorMsg := Value;

end;


function NoDevice(Config: TConfigRec): Boolean;
begin

  Result := IsEmpty(Config.Device.Description) or IsEmpty(Config.Device.Driver.OemInf);

end;

procedure SetDeviceValidity(var Device: TDeviceRec);
var
  Value: String;
  Phrases: Array[0..2] of String;
  I: Integer;
  Index: Integer;
  Parts: TArrayOfString;

begin

  if IsEmpty(Device.Description) then
  begin
    {No device, so empty record}
    Device.Recognized := True;
    Exit;
  end;

  Value := Uppercase(Device.Description);

  Phrases[0] := 'NOT MATCH THE DRIVER';
  Phrases[1] := 'NOT MATCH';
  Phrases[2] := 'NOT PROLIFIC';

  for I := Low(Phrases) to High(Phrases) do
  begin
    Index := Pos(Phrases[I], Value);

    {Matched, so device is not recognized}
    if Index <> 0 then
    begin
      Device.Recognized := False;
      Exit;
    end;

  end;

  {Not matched, so device is recognized}
  Device.Recognized := True;

  {Check for chip identification:
    PL2303HXA PHASED OUT SINCE 2012
    PL2303TA DO NOT SUPPORT WINDOWS 11 OR LATER
    PL2303TB DO NOT SUPPORT WINDOWS 11 OR LATER}

  if NotEmpty(Device.ErrorMsg) then
  begin
    Parts := SplitString(Device.ErrorMsg, #32);
    Device.ErrorMsg := '';

    if GetArrayLength(Parts) > 1 then
    begin
      Value := Trim(Parts[0]);

      if Pos('PL2303', Value) = 1 then
        Device.ErrorMsg := Value;
    end;
  end;

end;

{*************** Driver utility functions ***************}

procedure AddToDriverList(Rec: TDriverRec; var Drivers: TPLDrivers);
begin
  SetArrayLength(Drivers.Items, Drivers.Count + 1);
  Drivers.Items[Drivers.Count] := Rec;
  Inc(Drivers.Count);
end;

procedure ClearDriverList(var Drivers: TPLDrivers);
begin
  Drivers.Count := 0;
  SetArrayLength(Drivers.Items, 0);
end;

function CompareVersion(Driver1, Driver2: TDriverRec): Integer;
begin
  Result := ComparePackedVersion(Driver1.PackedVersion, Driver2.PackedVersion);
end;

procedure DebugDriver(Message: String; Driver: TDriverRec);
var
  DateVersion: String;

begin

  DateVersion := FormatDriverDateAndVersion(Driver, False);
  Debug(Format('%s: %s', [Message, DateVersion]));

end;

procedure DebugPLDrivers(Drivers: TPLDrivers);
var
  DriverStr: String;
  I: Integer;
  Rec: TDriverRec;

begin

  if Drivers.Count = 1 then
    DriverStr := 'driver'
  else
    DriverStr := 'drivers';

  Debug(Format('Found %d PL2303 %s', [Drivers.Count, DriverStr]));

  for I := 0 to Drivers.Count - 1 do
  begin
    Rec := Drivers.Items[I];
    Debug(Format('- %s (%s, %s)', [Rec.OemInf, Rec.Version, Rec.Date]));
  end;

end;

function GetDriverDateAndVersion(Data: String; var DriverRec: TDriverRec): Boolean;
var
  List: TArrayOfString;
  Separator: String;
  Date: String;
  Version: String;
  PackedVersion: Int64;

begin

  DriverRec.Date := '';
  DriverRec.Version := '0.0.0.0';
  DriverRec.PackedVersion := 0;

  {Inf files use a comma separator, pnputil output uses a space}
  if Pos(',', Data) <> 0 then
    Separator := ','
  else
    Separator := ' ';

  List := SplitString(Data, Separator);
  Result := GetArrayLength(List) = 2;

  if not Result then
    Exit;

  {Date is formated mm/dd/yyyy}
  Date := Trim(List[0]);
  Version := Trim(List[1]);
  Result := StrToVersion(Version, PackedVersion);

  if not Result then
    Exit;

  DriverRec.Version := Version;
  List := SplitString(Date, '/');
  Result := GetArrayLength(List) = 3;

  if Result then
  begin
    DriverRec.Date := Format('%s-%s-%s', [List[1], List[0], List[2]]);
    DriverRec.Version := Version;
    DriverRec.PackedVersion := PackedVersion;
  end;

end;

procedure InitDriverRec(var Rec: TDriverRec);
begin

  Rec.OemInf := '';
  Rec.OriginalInf := '';
  Rec.Version := '';
  Rec.PackedVersion := 0;
  Rec.Date := '';
  Rec.DisplayName := '';
  Rec.Exists := True;

end;

function IsDisplayedDriver(Driver1, Driver2: TDriverRec): Boolean;
begin

  Result := IsSameVersion(Driver1, Driver2);

  if not Result then
    Exit;

  Result := (Driver1.OemInf = Driver2.OemInf)
    and (Driver1.OriginalInf = Driver2.OriginalInf)
    and (Driver1.Exists = Driver2.Exists);

end;

function IsSameVersion(Driver1, Driver2: TDriverRec): Boolean;
begin

  if (Driver1.PackedVersion = 0) or (Driver2.PackedVersion = 0) then
  begin
    Result := False;
    Exit;
  end;

  Result := SamePackedVersion(Driver1.PackedVersion, Driver2.PackedVersion);

end;


{*************** Exec functions ***************}

function ExecPnp(Params: String): Boolean;
var
  ExitCode: Integer;

begin

  DebugExecBegin(GPnpExe, Params);
  Result := Exec(GPnpExe, Params, '', SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

end;

function ExecPnpDeleteDriver(Driver: TDriverRec): Boolean;
var
  Params: String;

begin

  Params := Format('/delete-driver %s', [ArgWin(Driver.OemInf)]);
  Result := ExecPnp(Params);

end;

function ExecPnpExportDriver(Driver: TDriverRec; var OriginalInf: String): Boolean;
var
  Params: String;

begin

  Result := False;
  OriginalInf := '';

  DebugDriver('Exporting driver for installation', Driver);

  if not DelTree(GExportDir + '\*', False, True, True) then
  begin
    Debug(Format('Failed to clear export directory: %s', [GExportDir]));
    Exit;
  end;

  Params := Format('/export-driver %s %s', [ArgWin(Driver.OemInf), ArgWin(GExportDir)]);

  if not ExecPnp(Params) then
    Exit;

  OriginalInf := GExportDir + '\' + Driver.OriginalInf;
  Result := True;

end;

function ExecPnpEnumDevices(var Output: TArrayOfString): Boolean;
var
  PnpParams: String;
  Params: String;
  ExitCode: Integer;

begin

  SetArrayLength(Output, 0);
  DeleteFile(GStdOut);

  AddParam(PnpParams, '/enum-devices');
  AddParam(PnpParams, '/class');
  AddParam(PnpParams, PORTSCLASS);
  AddParam(PnpParams, '/drivers');
  AddParam(PnpParams, '/connected');

  Params := Format('/c "%s %s >%s"', [ArgCmdModule(GPnpExe), PnpParams, ArgCmd(GStdOut)]);

  DebugExecBegin(GCmdExe, Params);
  Result := Exec(GCmdExe, Params, GTmpDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

  if Result then
    LoadStringsFromFile(GStdOut, Output);

end;

function ExecSaveProgram(Path: String): Boolean;
var
  Setup: String;
  Params: String;
  ExitCode: Integer;

begin

  Setup := ExpandConstant('{srcexe}');
  Params := Format('/c "copy %s %s"', [ArgCmd(Setup), ArgCmd(Path)]);

  DebugExecBegin(GCmdExe, Params);
  Result := Exec(GCmdExe, Params, GTmpDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

end;

function ExecUpdater(InfPath: String): Boolean;
var
  Params: String;
  ExitCode: Integer;

begin

  Params := ArgWin(InfPath);

  DebugExecBegin(GUpdaterExe, Params);
  Result := Exec(GUpdaterExe, Params, GTmpDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

end;


{*************** Common functions ***************}

{Adds a value to an existing string, separated with a linefeed.
All existing trailing space and linefeeds are removed first}
procedure AddLine(var Existing: String; Value: String);
begin

  if NotEmpty(Existing) then
  begin
    Existing := TrimRight(Existing);
    Existing := Existing + LF;
  end;

  AddStr(Existing, Value);

end;

{Adds a value to an existing string, separated with two linefeeds.
All existing trailing space and linefeeds are removed first}
procedure AddPara(var Existing: String; Value: String);
begin

  if NotEmpty(Existing) then
  begin
    Existing := TrimRight(Existing);
    Existing := Existing + LF2;
  end;

  AddStr(Existing, Value);

end;

{Adds a value separated by a space to a string of params. Note that the
value is expected to be escaped}
procedure AddParam(var Params: String; Value: String);
begin

  if NotEmpty(Params) then
  begin
    Params := TrimRight(Params);
    Params := Params + #32;
  end;

  AddStr(Params, Trim(Value));

end;

procedure AddStr(var Existing: String; Value: String);
begin
  Existing := Existing + Value;
end;

procedure Debug(Message: String);
begin
  Log('$ ' + Message);
end;

procedure DebugExecBegin(Exe, Params: String);
begin
  Debug('-- Execute File --');
  Debug(Format('Running %s %s', [ArgWin(Exe), Params]));
end;

procedure DebugExecEnd(Res: Boolean; ExitCode: Integer);
var
  Msg: String;

begin

  if Res then
    Msg := Format('Exit code [%d]', [ExitCode])
  else
    Msg := Format('Error: %s', [SysErrorMessage(DLLGetLastError)]);

  Debug(Msg);

end;

procedure DebugPageName(Id: Integer);
var
  Name: String;

begin

  case Id of
    {Inno built-in pages}
    wpWelcome                  : Name := 'Welcome';
    wpReady                    : Name := 'Ready to Install';
    wpPreparing                : Name := 'Preparing to Install';
    wpInstalling               : Name := 'Installing';
    wpFinished                 : Name := 'Setup Completed';
    {Custom pages}
    GPages.Start.ID            : Name := 'Custom Page: Start';
    GPages.Progress.ID         : Name := 'Custom Page: Updating';
    GPages.Finish.ID           : Name := 'Custom Page: Completed Updating';

  else
    Name := 'Unknown';
  end;

  Debug(Format('WizardPage [%.3d]: %s', [Id, Name]));

end;

function FormatDriverDateAndVersion(Driver: TDriverRec; ForDisplay: Boolean): String;
begin

  if not ForDisplay then
  begin
    if Driver.PackedVersion = 0 then
      Result := Format('%s (unknown)', [Driver.Version])
    else
      Result := Format('%s (%s)', [Driver.Version, Driver.Date]);
  end
  else
  begin
    if Driver.PackedVersion = 0 then
      Result := 'Not available'
    else
      Result := Format('%s  %s', [Driver.Version, Driver.Date]);
  end;

end;


{Returns true if a string is empty}
function IsEmpty(const Value: String): Boolean;
begin
  Result := Value = '';
end;


{Returns true if a string is not empty}
function NotEmpty(const Value: String): Boolean;
begin
  Result := Value <> '';
end;

procedure ShowErrorMessage(Message: String);
var
  Params: String;
  Suppressible: Boolean;

begin

  Params := GetCmdTail;
  Suppressible := Pos('/SUPPRESSMSGBOXES ', Uppercase(Params + #32)) <> 0;

  if WizardSilent and not Suppressible then
    Debug(Message)
  else
    SuppressibleMsgBox(Message, mbCriticalError, MB_OK, IDOK);

  if WizardForm <> nil then
    WizardForm.NextButton.Enabled := not WizardSilent;

end;

function SplitString(Value, Separator: String): TArrayOfString;
var
  Index: Integer;
  Count: Integer;
  Next: Integer;

begin

  Count := 0;
  Next := 0;

  repeat

    Index := Pos(Separator, Value);

    if Next = Count then
    begin
      Count := Count + 10;
      SetArrayLength(Result, Count);
    end;

    if Index > 0 then
    begin
      Result[Next] := Copy(Value, 1, Index - 1);
      Value := Copy(Value, Index + 1, Length(Value));
    end
    else
    begin
      Result[Next] := Value;
      Value := '';
    end;

    Inc(Next);

  until Length(Value) = 0;

  if Next < Count then
    SetArrayLength(Result, Next);

end;


{*************** Custom page functions ***************}

function FinishPageCreate(Id: Integer; Caption, Description: String): TWizardPage;
var
  Base: Integer;

begin

  Result := CreateCustomPage(Id, Caption, Description);
  CreateCurrentDriver(Result);

  Base := GetBase(GFinishPage.Current);

  GFinishPage.InfoHeader := TNewStaticText.Create(Result);

  with GFinishPage.InfoHeader do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(26);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop];
    AutoSize := True;
    Caption := 'Important information';
    Font.Style := [fsBold];
  end;

  Base := GetBase(GFinishPage.InfoHeader);

  GFinishPage.Info := TNewStaticText.Create(Result);

  with GFinishPage.Info do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(5);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop, akRight];
    AutoSize := True;
    WordWrap := True;
    Caption := '';
  end;

  Base := GetBase(GFinishPage.Info);
  GFinishPage.SaveButton := TNewButton.Create(Result);

  with GFinishPage.SaveButton do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(6);
    Caption := 'Save now';
    Width := WizardForm.CalculateButtonWidth([Caption]);
    Height := ScaleY(23);
    OnClick := @FinishPageSaveClick;
  end;

end;

procedure FinishPageUpdate(Config: TConfigRec; Update: TUpdateRec);
var
  S: String;
  DriverError: Boolean;
  Header: String;
  Base: Integer;

begin

  WizardForm.ActiveControl := Nil;
  GPages.Finish.Description := Update.Message;
  DriverError := False;

  SetCurrentDriver(GPages.Finish, Config);

  case Update.Status of
    UPDATE_ERROR:
      begin
        Header := 'Suggestions';

        if NoDevice(Config) then
        begin

          if not Update.Driver.Exists then
            {Either no drivers packaged or no driver selected}
            S := 'A device must be connected to find any PL2303 drivers.'
          else
            S := 'A device must be connected to update the selected driver.';

          AddStr(S, ' Please connect your device, then click Back to retry.');

        end
        else
        begin

          if not Update.Driver.Exists then
          begin
            {Either no drivers packaged or no driver selected}

            if Config.Packages[0].Exists then
              S := 'Please click Back and select a driver.'
            else
            begin
              S := 'Please reconnect your device, then click Back to retry. If this fails,';
              AddStr(S, ' use Windows Device Manager to find a PL2303 driver.');
            end;

          end
          else
          begin
            S := 'Please reconnect your device, then click Back to retry. If this fails,';
            AddStr(S, ' you may need to restart your computer and run this program again.');
          end;

        end;
      end;

    UPDATE_UNRECOGNIZED:
      begin
        Header := 'Advice';

        S := 'The driver does not recognize the microchip in your device, so it cannot be used.';
        AddStr(S, ' Click Back to retry with a different device, or contact your device supplier.');
      end;
  else
    begin
      Header := 'Information';

      DriverError := NotEmpty(Config.Device.ErrorMsg);

      if DriverError then
      begin
        S := 'The installed driver may not be the correct one for your device.';
        AddStr(S, ' Click Back to retry with a different driver.');
      end
      else
      begin
        S := 'It is recommended that you save this program on your computer. You will need it';
        AddStr(S, ' again if Windows Update changes your driver, or if you use different devices.');
      end;

    end;
  end;

  DriverError := DriverError or (Update.Status <> UPDATE_SUCCESS);
  GFinishPage.InfoHeader.Caption := Header;
  GFinishPage.Info.Caption := S;
  GFinishPage.SaveButton.Visible := not DriverError;

  if GFinishPage.SaveButton.Visible then
  begin
    Base := GetBase(GFinishPage.Info);
    GFinishPage.SaveButton.Top := Base + ScaleY(8);
  end;

end;

procedure FinishPageSaveClick(Sender: TObject);
var
  FilePath: String;
  FileName: String;
  Directory: String;
  Prompt: String;

begin

  Debug('User clicked Save now');

  FilePath := ExpandConstant('{srcexe}');
  FileName := ExtractFilename(FilePath);
  Prompt := Format('Choose where to save %s%s', [LF, FileName]);

  if not BrowseForFolder(Prompt, Directory, True) then
    Exit;

  FilePath := Directory + '\' + FileName;

  if not ExecSaveProgram(FilePath) then
    ShowErrorMessage('Unable to save file: ' + FilePath);

end;

procedure ProgressPageShow(Driver: TDriverRec);
var
  Msg: String;

begin

  Msg := Format('Please wait while driver version %s is installed.', [Driver.Version]);

  GPages.Progress.SetText('Updating:', Msg);
  GPages.Progress.ProgressBar.Position := 0;
  GPages.Progress.SetProgress(995, 1000);
  GPages.Progress.Show;

end;

function StartPageCreate(Id: Integer; Caption, Description: String): TWizardPage;
var
  Base: Integer;
  ScanButton: TNewButton;
  DriverText: TNewStaticText;
  InfoText: TNewStaticText;

begin

  Result := CreateCustomPage(Id, Caption, Description);
  CreateCurrentDriver(Result);

  Base := GetBase(GStartPage.Current);
  ScanButton := TNewButton.Create(Result);

  with ScanButton do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(6);
    Caption := 'Scan Drivers';
    Width := WizardForm.CalculateButtonWidth([Caption]);
    Height := ScaleY(23);
    OnClick := @StartPageScanClick;
  end;

  Base := GetBase(ScanButton);
  DriverText := TNewStaticText.Create(Result);

  with DriverText do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(12);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop];
    AutoSize := True;
    Caption := 'Select Driver';
    Font.Style := [fsBold];
  end;

  Base := GetBase(DriverText);
  GStartPage.Drivers := TNewCheckListBox.Create(Result);

  with GStartPage.Drivers do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(5);
    Width := Result.SurfaceWidth;
    Height := ScaleY(102);
    Anchors := [akLeft, akTop, akRight, akBottom];
    Flat := True;
    BorderStyle := bsNone;
    ParentColor := True;
    ShowLines := False;
    WantTabs := False;
  end;

  InfoText := TNewStaticText.Create(Result);

  with InfoText do
  begin
    Parent := Result.Surface;
    Top := Result.SurfaceHeight - ScaleY(24);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akBottom, akRight];
    AutoSize := True;
    { could be any of genuine, authentic, legitimate, recognized, official ...}
    Caption := 'This program will only work with authentic Prolific microchips.';
  end;

end;

procedure StartPageScanClick(Sender: TObject);
begin
  Debug('User clicked Scan Drivers');
  StartPageScanUpdate();
end;

procedure StartPageScanUpdate;
begin
  ConfigUpdate(GConfig);
  StartPageUpdate(GConfig);
end;

procedure StartPageUpdate(Config: TConfigRec);
var
  Index: Integer;
  Driver: TDriverRec;
  Caption: String;
  SubItem: String;
  Checked: Boolean;
  CheckedCount: Integer;
  Enabled: Boolean;

begin

  WizardForm.ActiveControl := Nil;
  SetCurrentDriver(GPages.Start, Config);
  CheckedCount := 0;

  GStartPage.Drivers.Items.Clear;

  for Index := 0 to Config.Drivers.Count -1 do
  begin
    Driver := Config.Drivers.Items[Index];

    Caption := Driver.DisplayName;
    SubItem := FormatDriverDateAndVersion(Driver, True);
    Checked := IsDisplayedDriver(Driver, GFlags.LastDriver);

    {Legacy drivers are listed first}
    case Index of
      0:
      begin
        Checked := Checked or DeviceError(Config.Device, 'PL2303HXA');
        Enabled := Driver.Exists;
      end;

      1:
      begin
        Checked := Checked or DeviceError(Config.Device, 'PL2303TA/PL2303TB');
        Enabled := Driver.Exists;
      end;

    else
      begin
        Checked := Checked or (Index = 2);
        Enabled := True;
      end;
    end;

    Checked := Checked and Enabled;

    if Checked then
      Inc(CheckedCount);

    if CheckedCount > 1 then
      Checked := False;

    GStartPage.Drivers.AddRadioButton(Caption, SubItem, 0, Checked, Enabled, nil);

    if Checked then
      GStartPage.Drivers.Selected[Index] := True;

  end;

end;


{*************** Custom page utility functions ***************}

{Single procedure to create current driver controls}
procedure CreateCurrentDriver(Page: TWizardPage);
var
  Base: Integer;
  CurrentText: TNewStaticText;
  Current: TNewCheckListBox;

begin

  CurrentText := TNewStaticText.Create(Page);

  with CurrentText do
  begin
    Parent := Page.Surface;
    Width := Page.SurfaceWidth;
    Anchors := [akLeft, akTop];
    AutoSize := True;
    Caption := 'Current Driver';
    Font.Style := [fsBold];
  end;

  Base := GetBase(CurrentText);

  Current := TNewCheckListBox.Create(Page);

  with Current do
  begin
    Parent := Page.Surface;
    Top := Base + ScaleY(5);
    Width := Page.SurfaceWidth;
    Height := ScaleY(18);
    Anchors := [akLeft, akTop, akRight];
    Flat := True;
    BorderStyle := bsNone;
    ParentColor := True;
    ShowLines := False;
    WantTabs := True;
    AddGroup('', '', 0, nil);
  end;

  if Page.ID = GPages.Start.ID then
    GStartPage.Current := Current
  else
    GFinishPage.Current := Current;

end;

function GetBase(Control: TWinControl): Integer;
begin
  Result := Control.Top + Control.Height;
end;

{Single procedure to set current driver data}
procedure SetCurrentDriver(Page: TWizardPage; Config: TConfigRec);
var
  Current: TNewCheckListBox;
  Caption: String;
  SubItem: String;

begin

  if Page.ID = GPages.Start.ID then
    Current := GStartPage.Current
  else
    Current := GFinishPage.Current;

  if NoDevice(Config) then
  begin
    Caption := 'Device not connected.';
    SubItem := '';
  end
  else
  begin
    Caption := Config.Device.Description;
    SubItem := FormatDriverDateAndVersion(Config.Device.Driver, True);
  end;

  Current.ItemCaption[0] := Caption;
  Current.ItemSubItem[0] := SubItem;

end;
