[Code]
type
  TDriverRec = record
    OemInf        : String;         {The Driver Name value}
    OriginalInf   : String;         {The Original Name value or full path to legacy driver}
    Version       : String;         {Driver version parsed from Driver Version}
    PackedVersion : Int64;          {Inno version format for comparisons}
    Date          : String;         {Driver release date parsed from Driver Version}
    DisplayName   : String;         {Simple description to show the user}
    Exists        : Boolean;        {Whether a legacy driver exists}
  end;

  TPLDrivers = record
    Count     : Integer;
    Items     : Array of TDriverRec;
  end;

  TInstanceRec = record
    HardwareId    : String;         {The Hardware Id from first part of Instance ID}
    Description   : String;         {The Device Description value}
    OemInf        : String;         {The Driver Name value}
    Driver        : TDriverRec;     {The installed driver for the device}
    Drivers       : TPLDrivers;     {Values from Matching Driver lines}
    Text          : TArrayOfString; {Temporary field to store lines while processing}
  end;

  TPLInstances = record
    Count     : Integer;
    Items     : Array of TInstanceRec;
  end;

  TBaseRec = record
    CmdExe  : String;       {full pathname to system cmd}
    PnpExe  : String;       {full pathname to system pnputil}
    TmpDir  : String;       {the temp directory that Inno uses}
    StdOut  : String;       {the temp file used to capture stdout}
  end;

var
  GBase: TBaseRec;

const
  LF = #13#10;
  SP = #32;

  DRIVER_INF = 'ser2pl.inf';
  LEGACY_HXA = '3.3.11.152';
  LEGACY_TAB = '3.8.36.2';
  MIN_DRIVER = '3.8.36.0';

  PORTSCLASS = '{4d36e978-e325-11ce-bfc1-08002be10318}';

{Init functions}
procedure InitCommon; forward;
procedure ThemeInit; forward;

{Driver discovery functions}
function GetPLInstances(PnpOutput: TArrayOfString): TPLInstances; forward;
function IsMatchingInstance(InstanceLine: String; var HardwareId: String): Boolean; forward;
procedure ParsePLInstances(var Instances: TPLInstances); forward;
procedure ProcessPLInstance(var Instance: TInstanceRec); forward;
procedure ProcessPLMatchingDrivers(var Instance: TInstanceRec); forward;

{Driver utility functions}
procedure AddToDriverList(Rec: TDriverRec; var Drivers: TPLDrivers); forward;
procedure ClearDriverList(var Drivers: TPLDrivers); forward;
function GetDriverDateAndVersion(Data: String; var DriverRec: TDriverRec): Boolean; forward;
function IsSameVersion(Driver1, Driver2: TDriverRec): Boolean; forward;

{Exec functions}
function ExecPnp(EscapedParams: String): Boolean; forward;
function ExecPnpDeleteDriver(Driver: TDriverRec; Uninstall: Boolean): Boolean; forward;
function ExecPnpEnumDevices(Connected: Boolean; var Output: TArrayOfString): Boolean; forward;

{Common functions}
procedure AddText(var Existing: String; Value: String); forward;
procedure AddTo(var Existing: String; Separator, Value: String); forward;
procedure AddToArray(var StrArray: TArrayOfString; Value: String); forward;
procedure Debug(Message: String); forward;
procedure DebugExecBegin(Exe, EscapedParams: String); forward;
procedure DebugExecEnd(Res: Boolean; ExitCode: Integer); forward;
function IsEmpty(const Value: String): Boolean; forward;
function NotEmpty(const Value: String): Boolean; forward;
function SplitString(Value, Separator: String): TArrayOfString; forward;


{*************** Init functions ***************}

procedure InitCommon;
begin
  GBase.CmdExe := ExpandConstant('{cmd}');
  GBase.PnpExe := ExpandConstant('{sys}') + '\pnputil.exe';
  GBase.TmpDir := ExpandConstant('{tmp}');
  GBase.StdOut := GBase.TmpDir + '\stdout.txt';
end;

{Sets the font color to dark grey}
procedure ThemeInit;
var
  Color: Integer;

begin

  {Hex 303030}
  Color := (30 shl 16) + (30 shl 8) + 30;

  if not IsUninstaller then
    WizardForm.Font.Color := Color
  else
    UninstallProgressForm.Font.Color := Color;

end;


{*************** Driver discovery functions ***************}

{Parses pnputil output to create an array of instances}
function GetPLInstances(PnpOutput: TArrayOfString): TPLInstances;
var
  Count: Integer;
  I: Integer;
  Index: Integer;
  IsMatching: Boolean;
  Line: String;
  HardwareId: String;

begin

  Count := GetArrayLength(PnpOutput);
  Result.Count := 0;
  IsMatching := False;

  for I := 0 to Count - 1 do
  begin
    Line := Trim(PnpOutput[I]);

    if Pos('Instance ID:', Line) = 1 then
    begin

      IsMatching := IsMatchingInstance(Line, HardwareId);

      if IsMatching then
      begin
        Index := Result.Count;
        Inc(Result.Count);
        SetArrayLength(Result.Items, Result.Count);
        Result.Items[Index].HardwareId := HardwareId;
      end;
    end;

    if IsMatching then
      AddToArray(Result.Items[Index].Text, Line);

  end;

end;

{Returns true if this is the Hardware instance we are looking for}
function IsMatchingInstance(InstanceLine: String; var HardwareId: String): Boolean;
var
  Value: String;
  Ids: Array[0..1] of String;
  I: Integer;

begin

  Result := False;
  Value := Uppercase(InstanceLine);

  {Make sure we get relevant PL2303 ids}
  Ids[0] := 'USB\VID_067B&PID_2303';
  Ids[1] := 'USB\VID_067B&PID_2304';

  for I := Low(Ids) to High(Ids) do
  begin

    if Pos(Ids[I], Value) <> 0 then
    begin
      HardwareId := Ids[I];
      Result := True;
      Break;
    end;

  end;

end;

{Iterates the Instance records and parses out the values}
procedure ParsePLInstances(var Instances: TPLInstances);
var
  I: Integer;

begin

  for I := 0 to Instances.Count - 1 do
  begin
    ProcessPLInstance(Instances.Items[I]);
    ProcessPLMatchingDrivers(Instances.Items[I]);
  end;

end;

{Parses text to get the Device Description and Driver Name
values then replaces the text with the MatchingDriver lines}
procedure ProcessPLInstance(var Instance: TInstanceRec);
var
  Count: Integer;
  I: Integer;
  Line: String;
  Start: Integer;
  Description: String;
  DriverName: String;
  Drivers: TArrayOfString;

begin

  Count := GetArrayLength(Instance.Text);
  Description := 'Device Description:';
  DriverName := 'Driver Name:';
  I := 0;

  while I < Count do
  begin
    Line := Trim(Instance.Text[I]);
    Inc(I);

    if Pos(Description, Line) = 1 then
    begin
      Start := Length(Description) + 1;
      Instance.Description := Trim(Copy(Line, Start, MaxInt));
      Continue;
    end;

    if Pos(DriverName, Line) = 1 then
    begin
      Start := Length(DriverName) + 1;
      Instance.OemInf := Trim(Copy(Line, Start, MaxInt));
      Continue;
    end;

    if Pos('Matching Drivers:', Line) = 1 then
    begin
      {Add Matching Drivers lines}
      while I < Count do
      begin
        Line := Trim(Instance.Text[I]);
        Inc(I);
        AddToArray(Drivers, Line);
      end;
    end;

  end;

  Instance.Text := Drivers;

end;

{Parses text to get the MatchingDriver values}
procedure ProcessPLMatchingDrivers(var Instance: TInstanceRec);
var
  Count: Integer;
  I: Integer;
  Values: TArrayOfString;
  Key: String;
  Value: String;
  ExpectedKey: String;
  DriverRec: TDriverRec;

begin

  Count := GetArrayLength(Instance.Text);
  DriverRec.Exists := True;
  ExpectedKey := 'Driver Name';

  for I := 0 to Count - 1 do
  begin
    Values := SplitString(Trim(Instance.Text[I]), ':');

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
      AddToDriverList(DriverRec, Instance.Drivers);

      {See if this is the installed driver}
      if DriverRec.OemInf = Instance.OemInf then
        Instance.Driver := DriverRec;

      ExpectedKey := 'Driver Name';
    end;
  end;

  {Clear Text array}
  SetArrayLength(Instance.Text, 0);

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

function ExecPnp(EscapedParams: String): Boolean;
var
  ExitCode: Integer;

begin

  DebugExecBegin(GBase.PnpExe, EscapedParams);
  Result := Exec(GBase.PnpExe, EscapedParams, '', SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

end;

function ExecPnpDeleteDriver(Driver: TDriverRec; Uninstall: Boolean): Boolean;
var
  Params: String;

begin

  Params := Format('/delete-driver %s', [ArgWin(Driver.OemInf)]);

  if Uninstall then
    AddText(Params, '/uninstall /force');

  Result := ExecPnp(Params);

end;

function ExecPnpEnumDevices(Connected: Boolean; var Output: TArrayOfString): Boolean;
var
  PnpParams: String;
  Params: String;
  ExitCode: Integer;

begin

  SetArrayLength(Output, 0);
  DeleteFile(GBase.StdOut);

  PnpParams := Format('/enum-devices /class %s /drivers', [PORTSCLASS]);

  if Connected then
    AddText(PnpParams, '/connected');

  Params := Format('/c "%s %s >%s"', [ArgCmdModule(GBase.PnpExe), PnpParams, ArgCmd(GBase.StdOut)]);

  DebugExecBegin(GBase.CmdExe, Params);
  Result := Exec(GBase.CmdExe, Params, GBase.TmpDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
  DebugExecEnd(Result, ExitCode);
  Result := Result and (ExitCode = 0);

  if Result then
    LoadStringsFromFile(GBase.StdOut, Output);

end;


{*************** Common functions ***************}

{Adds a value to an existing string, separated with a space}
procedure AddText(var Existing: String; Value: String);
begin
  AddTo(Existing, SP, Value);
end;

{Adds a value to an existing string, separated by Separator}
procedure AddTo(var Existing: String; Separator, Value: String);
begin

  if NotEmpty(Existing) then
  begin
    Existing := TrimRight(Existing);
    Existing := Existing + Separator;
  end;

  Existing := Existing + Trim(Value);
end;

{Adds a value to a TArrayOfString}
procedure AddToArray(var StrArray: TArrayOfString; Value: String);
var
  NextIndex: Integer;

begin

  NextIndex := GetArrayLength(StrArray);
  SetArrayLength(StrArray, NextIndex + 1);
  StrArray[NextIndex] := Value;

end;

procedure Debug(Message: String);
begin
  Log('$ ' + Message);
end;

procedure DebugExecBegin(Exe, EscapedParams: String);
begin
  Debug('-- Execute File --');
  Debug(Format('Running %s %s', [Exe, EscapedParams]));
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
