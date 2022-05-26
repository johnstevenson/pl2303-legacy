; a config.iss file is required
#ifndef Config
  #ifexist "config.iss"
    #include "config.iss"
  #endif
#endif

#ifndef Release
  #define OutputDir "..\builds\output\"
  #define OutputBaseFilename StringChange(AppName, " ", "")
#endif

#define PnpUpdaterExe "PnpUpdater.exe"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}

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
DisableFinishedPage=yes
CreateAppDir=no
CloseApplications=no

; uninstall
Uninstallable=no

; cosmetic
WizardStyle=modern
WizardSizePercent=110,110
WizardSmallImageFile=wizimage.bmp
SetupIconFile=wizicon.ico

; output
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}

[LangOptions]
DialogFontSize=10

[Files]
Source: pnp\bin\Release\{#PnpUpdaterExe}; Flags: dontcopy;
#ifdef DriverPath
  Source: {#DriverPath}\*.*; DestDir: drivers; Flags: recursesubdirs dontcopy;
#endif

[Messages]
SetupAppTitle={#AppName}
SetupWindowTitle={#AppName} {#AppVersion}

#include "shared\escape.iss"
#include "shared\common.iss"

[Code]
type
  TLegacyDrivers = Array[0..1] of TDriverRec;

  TDeviceRec = record
    InstanceCount : Integer;        {The number of connected devices}
    HardwareId    : String;         {The Hardware Id from first part of Instance ID}
    Description   : String;         {The Device Description value}
    ErrorStatus   : Integer;        {For Device Description error messages}
    ErrorHint     : String;         {The chip indentification in Description error messages}
    Driver        : TDriverRec;     {The installed driver for the device}
  end;

  TConfigRec = record
    Drivers     : TPLDrivers;       {drivers from connected device}
    LegacyStore : TPLDrivers;       {legacy drivers installed in driver store}
    Packages    : TLegacyDrivers;   {legacy driver packages for installation}
    Device      : TDeviceRec;       {the connected device}
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
    Start       : TWizardPage;
    Progress    : TOutputProgressWizardPage;
    Status      : TWizardPage;
    Finish      : TWizardPage;
  end;

  TStartPage = record
    Current     : TNewCheckListBox;
    Drivers     : TNewCheckListBox;
  end;

  TStatusPage = record
    Current     : TNewCheckListBox;
    InfoHeader  : TNewStaticText;
    Info        : TNewStaticText;
  end;

var
  GUpdaterExe: String;              {full pathname to installer updater}
  GConfig: TConfigRec;              {contains driver and status data}
  GUpdate: TUpdateRec;              {contains data from the update}
  GFlags: TFlagsRec;                {contains runtime flags}
  GExportDir: String;               {folder to export to in temp directory}
  GPages: TCustomPages;             {group of custom pages}
  GStartPage: TStartPage;           {contains Start page controls}
  GStatusPage: TStatusPage;         {contains Status page controls}

const
  APP_NAME = '{#AppName}';
  ACTION_INSTALL = 1;
  ACTION_UNINSTALL = 2;

  UPDATER_EXE = '{#PnpUpdaterExe}';

  DEVICE_ERROR_NONE = 0;
  DEVICE_ERROR_GENERIC = 1;
  DEVICE_ERROR_UNRECOGNIZED = 2;

  UPDATE_SUCCESS = 0;
  UPDATE_ERROR = 100;
  UPDATE_UNRECOGNIZED = 200;

{Init functions}
function ConfigInit(var Config: TConfigRec): Boolean; forward;
function GetLegacyPackage(DriverPath, Folder: String; var Exists, Error: Boolean): TDriverRec; forward;

{Driver discovery functions}
procedure ConfigUpdate(var Config: TConfigRec); forward;
function GetPLDrivers(var Device: TDeviceRec): TPLDrivers; forward;
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
function DeviceHasError(Device: TDeviceRec): Boolean; forward;
function DeviceHint(Device: TDeviceRec; Error: String): Boolean; forward;
function DeviceNotRecognized(Device: TDeviceRec): Boolean; forward;
procedure InitDeviceRec(var Rec: TDeviceRec); forward;
function IsExpectedDescription(Description: String): Boolean; forward;
function HasComPort(Description: String): Boolean; forward;
function MultiDevice(Config: TConfigRec): Boolean; forward;
function NoDevice(Config: TConfigRec): Boolean; forward;
procedure SetDeviceValidity(Instances: TPLInstances; var Device: TDeviceRec); forward;

{Driver utility functions}
function CompareVersion(Driver1, Driver2: TDriverRec): Integer; forward;
procedure DebugDriver(Message: String; Driver: TDriverRec); forward;
procedure DebugPLDrivers(Drivers: TPLDrivers); forward;
function FormatDriverDateAndVersion(Driver: TDriverRec; ForDisplay: Boolean): String; forward;
procedure InitDriverRec(var Rec: TDriverRec); forward;
function IsDisplayedDriver(Driver1, Driver2: TDriverRec): Boolean; forward;

{Exec functions}
function ExecPnpExportDriver(Driver: TDriverRec; var OriginalInf: String): Boolean; forward;
function ExecUpdater(HardwareId, InfPath: String): Boolean; forward;

{Common functions}
procedure DebugPageName(Id: Integer); forward;
procedure ShowErrorMessage(Message: String); forward;

{Custom page functions}
function FinishPageCreate(Id: Integer): TWizardPage; forward;
procedure ProgressPageShow(Driver: TDriverRec); forward;
function StartPageCreate(Id: Integer): TWizardPage; forward;
procedure StartPageScanClick(Sender: TObject); forward;
procedure StartPageScanUpdate; forward;
procedure StartPageUpdate(Config: TConfigRec); forward;
function StatusPageCreate(Id: Integer): TWizardPage; forward;
function StatusPageGetError(Config: TConfigRec; Update: TUpdateRec): String; forward;
procedure StatusPageUpdate(Config: TConfigRec; Update: TUpdateRec); forward;

{Custom page utility functions}
procedure CreateCurrentDriver(Page: TWizardPage); forward;
function GetBase(Control: TWinControl): Integer; forward;
procedure SetCurrentDriver(Page: TWizardPage; Config: TConfigRec); forward;

function InitializeSetup(): Boolean;
var
  S: String;

begin

  InitCommon();

  GExportDir := GBase.TmpDir + '\export';
  GUpdaterExe := GBase.TmpDir + '\' + UPDATER_EXE;

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
    AddTo(S, LF + LF, 'Package configuration error.');
    ShowErrorMessage(S);
  end;

end;

procedure InitializeWizard;
begin

  ThemeInit();

  GPages.Start := StartPageCreate(wpWelcome);
  GPages.Status := StatusPageCreate(GPages.Start.ID);
  GPages.Finish := FinishPageCreate(wpInstalling);

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
  else if CurPageID = GPages.Status.ID then
    StatusPageUpdate(GConfig, GUpdate);

  if CurPageID = GPages.Finish.ID then
    WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
  else
    WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);

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
  DriverPath := GBase.TmpDir + '\drivers';

  {Legacy HXA}
  Package := GetLegacyPackage(DriverPath, LEGACY_HXA, Exists, Error);
  DebugDriver('Registering legacy HXA package', Package);

  if Error then
  begin
    Debug('Error in legacy HXA package');
    Exit;
  end;

  Package.DisplayName := 'Legacy PL2303 HXA/XA';
  Package.Exists := Exists;
  Config.Packages[0] := Package;

  {Legacy TA/TB}
  Package := GetLegacyPackage(DriverPath, LEGACY_TAB, Exists, Error);
  DebugDriver('Registering legacy TA/TB package', Package);

  if Error then
  begin
    Debug('Error in legacy TA/TB package');
    Exit;
  end;

  Package.DisplayName := 'Legacy PL2303 TA/TB';
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


{*************** Driver discovery functions ***************}

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

  {Add LegaxyHXA/XA}
  Driver := Config.Packages[0];

  if IsSameVersion(Device.Driver, Driver) then
  begin
    Matched := True;
    AddText(Driver.DisplayName, '(current driver)');
  end;

  AddToDriverList(Driver, Config.Drivers);

  {Add LegaxyTA/TB}
  Driver := Config.Packages[1];

  if not Matched and IsSameVersion(Device.Driver, Driver) then
  begin
    Matched := True;
    AddText(Driver.DisplayName, '(current driver)');
  end;

  AddToDriverList(Driver, Config.Drivers);

  {Add sorted drivers and legacy store}
  ItemizeDrivers(Drivers, Matched, Config);

end;

function GetPLDrivers(var Device: TDeviceRec): TPLDrivers;
var
  Output: TArrayOfString;
  Instances: TPLInstances;

begin

  Debug('Seaching for a connected PL2303 device');

  if not ExecPnpEnumDevices(True, Output) then
    Exit;

  Instances := GetPLInstances(Output);

  if Instances.Count <> 1 then
  begin

    if Instances.Count > 1 then
      Debug('More than one device is connected');

    SetDeviceValidity(Instances, Device);
  end
  else
  begin
    ParsePLInstances(Instances);
    SetDeviceValidity(Instances, Device);
    Result := Instances.Items[0].Drivers;
  end;

  DebugPLDrivers(Result);

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
        AddText(Driver.DisplayName, '(current driver)');

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

  {Clear last driver}
  GFlags.LastDriver := Driver;

  {See if we have a driver selected}
  Index := GStartPage.Drivers.ItemIndex;

  if Index <> -1 then
    Driver := Config.Drivers.Items[Index];

  {Always skip with multiple devices because even though the update
  could work, we only parse the first instance found}
  if MultiDevice(Config) then
  begin
    Debug('Skipping update, multiple devices');
    SetUpdateRec(Config, Driver, UPDATE_ERROR, False);
    Exit;
  end;

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

  {Set last driver}
  GFlags.LastDriver := Driver;

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

  if DeviceNotRecognized(TestDevice) then
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

    if DeviceNotRecognized(Config.Device) then
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

  if not ExecUpdater(Config.Device.HardwareId, InfPath) then
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

    {The driver will only be removed if it is not registered
    to another device}
    if not ExecPnpDeleteDriver(LegacyDriver, False) then
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

    GUpdate.Message := 'Error:';

    if MultiDevice(Config) then
      AddText(GUpdate.Message, 'Multiple devices')
    else if NoDevice(Config) then
      AddText(GUpdate.Message, 'Not connected')
    else
    begin

      if not Driver.Exists then
        AddText(GUpdate.Message, 'No driver selected')
      else
      begin

        if Status = UPDATE_UNRECOGNIZED then
          AddText(GUpdate.Message, 'Unrecognized hardware')
        else
          AddText(GUpdate.Message, 'Unable to install the selected driver');

      end;

    end;

  end
  else
  begin

    if SameDriver then
      GUpdate.Message := 'The driver is already installed'
    else
      GUpdate.Message :=  'The selected driver has been installed';

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

  if DeviceNotRecognized(TestDevice) then
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
  so that this is shown on the status page}
  if DeviceNotRecognized(TestDevice) then
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

function DeviceHasError(Device: TDeviceRec): Boolean;
begin
  Result := Device.ErrorStatus = DEVICE_ERROR_GENERIC;
end;

function DeviceHint(Device: TDeviceRec; Error: String): Boolean;
var
  Parts: TArrayOfString;
  Count: Integer;
  I: Integer;

begin

  Result := False;

  if not DeviceHasError(Device) then
    Exit;

  Parts := SplitString(Error, '/');
  Count := GetArrayLength(Parts);

  for I := 0 to Count - 1 do
  begin

    if Device.ErrorHint = Parts[I] then
    begin
      Result := True;
      Break;
    end;

  end;

end;

function DeviceNotRecognized(Device: TDeviceRec): Boolean;
begin
  Result := Device.ErrorStatus = DEVICE_ERROR_UNRECOGNIZED;
end;

procedure InitDeviceRec(var Rec: TDeviceRec);
begin

  Rec.InstanceCount := 0;
  Rec.HardwareId := '';
  Rec.Description := '';
  Rec.ErrorStatus := 0;
  Rec.ErrorHint := '';

  InitDriverRec(Rec.Driver);
  GetDriverDateAndVersion('', Rec.Driver);

end;

function IsExpectedDescription(Description: String): Boolean;
var
  Value: String;
  Phrases: Array[0..4] of String;
  I: Integer;

begin

  Result := True;

  if Pos('Prolific USB-to-Serial Comm Port', Description) = 1 then
    Exit;

  if Pos('Prolific USB-to-GPIO/PWM Port', Description) = 1 then
    Exit;

  if HasComPort(Description) then
    Exit;

  Value := Uppercase(Description);

  Phrases[0] := 'PLEASE CONTACT';
  Phrases[1] := 'NOT SUPPORTED';
  Phrases[2] := 'PHASED OUT';
  Phrases[3] := 'PLEASE INSTALL';
  Phrases[4] := 'WINDOWS 11';

  for I := Low(Phrases) to High(Phrases) do
  begin

    if Pos(Phrases[I], Value) <> 0 then
    begin
      Result := False;
      Break;
    end;

  end;

end;

function HasComPort(Description: String): Boolean;
var
  Value: String;
  Index: Integer;

begin

  Result := False;
  Value := Uppercase(Description);

  Index := Pos('(COM', Value);

  if Index = 0 then
    Exit;

  Value := Copy(Value, Index + 4, MaxInt);
  Index := Pos(')', Value);

  if Index <> 0 then
  begin
    Delete(Value, Index, Maxint);
    Result := StrToIntDef(Value, 0) <> 0;
  end;

end;

function MultiDevice(Config: TConfigRec): Boolean;
begin
  Result := Config.Device.InstanceCount > 1;
end;

function NoDevice(Config: TConfigRec): Boolean;
begin
  Result := Config.Device.InstanceCount = 0;
end;

procedure SetDeviceValidity(Instances: TPLInstances; var Device: TDeviceRec);
var
  Instance: TInstanceRec;
  Phrases: Array[0..3] of String;
  I: Integer;
  Parts: TArrayOfString;
  Value: String;

begin

  Device.InstanceCount := Instances.Count;

  {No device or multi device, so empty record}
  if Device.InstanceCount <> 1 then
    Exit;

  {Tranfers Instances data}
  Instance := Instances.Items[0];
  Device.HardwareId := Instance.HardwareId;
  Device.Description := Instance.Description;
  Device.Driver := Instance.Driver;

  {Everthing okay}
  if IsExpectedDescription(Device.Description) then
    Exit;

  {Not all messages are upper-cased and they are easier
  to read in the list box if they are}
  Device.Description := Uppercase(Device.Description);
  Device.ErrorStatus := DEVICE_ERROR_GENERIC;

  {Check for unrecognized chips:
    THIS IS NOT PROLIFIC PL2303. PLEASE CONTACT YOUR SUPPLIER.
    YOUR PRODUCT DOES NOT MATCH THE DRIVER. PLEASE CONTACT YOUR SUPPLIER.}

  Phrases[0] := 'NOT PROLIFIC PL2303';
  Phrases[1] := 'NOT MATCH THE DRIVER';
  Phrases[2] := 'NOT PROLIFIC';
  Phrases[3] := 'NOT MATCH';

  for I := Low(Phrases) to High(Phrases) do
  begin

    if Pos(Phrases[I], Device.Description) <> 0 then
    begin
      {Phrase found, so device is not recognized}
      Device.ErrorStatus := DEVICE_ERROR_UNRECOGNIZED;
      Exit;
    end;

  end;

  {Check for chip identification in description:
    PL2303HXA PHASED OUT SINCE 2012. PLEASE CONTACT YOUR SUPPLIER.
    PL2303TA DO NOT SUPPORT WINDOWS 11 OR LATER, PLEASE CONTACT YOUR SUPPLIER.
    PL2303TB DO NOT SUPPORT WINDOWS 11 OR LATER, PLEASE CONTACT YOUR SUPPLIER.
    Please install corresponding PL2303 driver to support Windows 11 and further OS.}

  Parts := SplitString(Device.Description, SP);

  if GetArrayLength(Parts) > 1 then
  begin
    Value := Trim(Parts[0]);

    if Pos('PL2303', Value) = 1 then
      Device.ErrorHint := Value;

  end;

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


{*************** Exec functions ***************}

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

function ExecUpdater(HardwareId, InfPath: String): Boolean;
var
  Params: String;
  ExitCode: Integer;

begin

  Params := ArgWin(HardwareId);
  AddText(Params, ArgWin(InfPath));

  DebugExecBegin(GUpdaterExe, Params);
  Result := Exec(GUpdaterExe, Params, GBase.TmpDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

end;


{*************** Common functions ***************}

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
    {Custom pages}
    GPages.Start.ID            : Name := 'Custom Page: Start';
    GPages.Progress.ID         : Name := 'Custom Page: Updating';
    GPages.Status.ID           : Name := 'Custom Page: Status';
    GPages.Finish.ID           : Name := 'Custom Page: Completed';

  else
    Name := 'Unknown';
  end;

  Debug(Format('WizardPage [%.3d]: %s', [Id, Name]));

end;

procedure ShowErrorMessage(Message: String);
var
  Params: String;
  Suppressible: Boolean;

begin

  Params := GetCmdTail;
  Suppressible := Pos('/SUPPRESSMSGBOXES ', Uppercase(Params + SP)) <> 0;

  if WizardSilent and not Suppressible then
    Debug(Message)
  else
    SuppressibleMsgBox(Message, mbCriticalError, MB_OK, IDOK);

  if WizardForm <> nil then
    WizardForm.NextButton.Enabled := not WizardSilent;

end;


{*************** Custom page functions ***************}

function FinishPageCreate(Id: Integer): TWizardPage;
var
  Title: String;
  Text: String;
  Info: TNewStaticText;

begin

  {We could have used CreateOutputMsgPage, but this allows
  for any future customization}

  Title := Format('%s has completed', [APP_NAME]);
  Text:= 'Run this progam again if your driver has changed.';
  Result := CreateCustomPage(Id, Title, Text);

  Info := TNewStaticText.Create(Result);

  with Info do
  begin
    Parent := Result.Surface;
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop, akRight];
    AutoSize := True;
    WordWrap := True;
    Caption := 'Click Finish to exit.';
  end;

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

function StartPageCreate(Id: Integer): TWizardPage;
var
  Title: String;
  Text: String;
  Base: Integer;
  ScanButton: TNewButton;
  DriverText: TNewStaticText;
  InfoText: TNewStaticText;

begin

  Title := 'PL2303 legacy USB drivers';
  Text := 'For devices that use unsupported Prolific microchips. If the current driver';
  AddText(Text, 'is not shown below, connect your device and click Scan Drivers.');

  Result := CreateCustomPage(Id, Title, Text);
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
        Checked := Checked or DeviceHint(Config.Device, 'PL2303HXA');
        Enabled := Driver.Exists;
      end;

      1:
      begin
        Checked := Checked or DeviceHint(Config.Device, 'PL2303TA/PL2303TB');
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

function StatusPageCreate(Id: Integer): TWizardPage;
var
  Title: String;
  Base: Integer;

begin

  Title := 'Driver update status';
  Result := CreateCustomPage(Id, Title, '');
  CreateCurrentDriver(Result);

  Base := GetBase(GStatusPage.Current);

  GStatusPage.InfoHeader := TNewStaticText.Create(Result);

  with GStatusPage.InfoHeader do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(5);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop];
    AutoSize := True;
    Caption := 'Important information';
    Font.Style := [fsBold];
  end;

  Base := GetBase(GStatusPage.InfoHeader);

  GStatusPage.Info := TNewStaticText.Create(Result);

  with GStatusPage.Info do
  begin
    Parent := Result.Surface;
    Top := Base + ScaleY(5);
    Width := Result.SurfaceWidth;
    Anchors := [akLeft, akTop, akRight];
    AutoSize := True;
    WordWrap := True;
    Caption := '';
  end;

end;

function StatusPageGetError(Config: TConfigRec; Update: TUpdateRec): String;
begin

  Result := '';

  {Multi devices}
  if MultiDevice(Config) then
  begin
     Result := 'Only one device should be connected to update a PL2303 driver.'
     AddText(Result, 'Please reconnect with a single device, then click Back to retry.');
     Exit;
  end;

  {No device}
  if NoDevice(Config) then
  begin

    if not Update.Driver.Exists then
      {Either no drivers packaged or no driver selected}
      Result := 'A device must be connected to find any PL2303 drivers.'
    else
      Result := 'A device must be connected to update the selected driver.';

    AddText(Result, 'Please connect your device, then click Back to retry.');
    Exit;

  end;

  {Either no drivers packaged or no driver selected}
  if not Update.Driver.Exists then
  begin

    if Config.Packages[0].Exists then
      Result := 'Please click Back and select a driver.'
    else
    begin
      Result := 'Please reconnect your device, then click Back to retry. If this fails,';
      AddText(Result, 'use Windows Device Manager to find a PL2303 driver.');
    end;

    Exit;

  end;

  {The update itself failed}
  Result := 'Please reconnect your device, then click Back to retry. If this fails,';
  AddText(Result, 'you may need to restart your computer and run this program again.');

end;

procedure StatusPageUpdate(Config: TConfigRec; Update: TUpdateRec);
var
  S: String;
  Header: String;

begin

  WizardForm.ActiveControl := Nil;
  GPages.Status.Description := Update.Message;

  SetCurrentDriver(GPages.Status, Config);

  case Update.Status of
    UPDATE_ERROR:
      begin
        Header := 'Suggestions';
        S := StatusPageGetError(Config, Update);
      end;

    UPDATE_UNRECOGNIZED:
      begin
        Header := 'Suggestions';

        S := 'The driver does not recognize the microchip in your device.';
        AddText(S, 'Click Back to retry with a different device, or contact your device supplier.');
      end;
  else
    begin
      Header := 'Information';

      if DeviceHasError(Config.Device) then
      begin
        S := 'The installed driver will not work with your device.';
        AddText(S, 'Click Back to retry with a different driver.');
      end
      else
      begin
        S := 'You will need to run this program again if Windows Update changes your driver,';
        AddText(S, 'or if you use other devices that require a different PL2303 driver.');
      end;

    end;
  end;

  GStatusPage.InfoHeader.Caption := Header;
  GStatusPage.Info.Caption := S;

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
    Height := ScaleY(34);
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
    GStatusPage.Current := Current;

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
    Current := GStatusPage.Current;

  SubItem := '';

  if MultiDevice(Config) then
    Caption := 'Multiple devices connected'
  else if NoDevice(Config) then
    Caption := 'Device not connected'
  else
  begin
    Caption := Config.Device.Description;
    SubItem := FormatDriverDateAndVersion(Config.Device.Driver, True);
  end;

  Current.ItemCaption[0] := Caption;
  Current.ItemSubItem[0] := SubItem;

end;
