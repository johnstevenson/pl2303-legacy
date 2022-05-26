[Code]
type
  TUserDriverRec = record
    Driver    : TDriverRec;
    Delete    : Boolean;
  end;

  TUserDriverList = Array[0..1] of TUserDriverRec;

  TDriverForm = record
    Main: TSetupForm;
    ListBox: TNewCheckListBox;
  end;

var
  GUserForm: TDriverForm;

procedure UserDriversDelete; forward;
function UserDriversGet: TUserDriverList; forward;
function UserDriversGetInstalled: TPLDrivers; forward;
function UserDriversGetLegacy: TUserDriverList; forward;
function UserDriversInit(DisplayName, Version: String): TDriverRec; forward;
function UserDriversSelect(var List: TUserDriverList): Boolean; forward;
function UserDriversCreateForm: TDriverForm; forward;
function UserDriversSilent: Boolean; forward;


procedure UserDriversDelete;
var
  List: TUserDriverList;
  I: Integer;
  Action: String;

begin

  List := UserDriversGet();

  if not UserDriversSelect(List) then
    Exit;

  for I := Low(List) to High(List) - 1 do
  begin

    if List[I].Delete then
    begin
      if ExecPnpDeleteDriver(List[I].Driver, True) then
        Action := 'Removed'
      else
        Action := 'Failed to remove';

      Debug(Format('%s legacy driver: %s', [Action, List[I].Driver.Version]));
    end;

  end;

end;

function UserDriversGet: TUserDriverList;
var
  Drivers: TPLDrivers;
  I: Integer;
  Found: Integer;
  Driver: TDriverRec;

begin

  Result := UserDriversGetLegacy();
  Drivers := UserDriversGetInstalled();
  Found := 0;

  {See if any installed driver matches legacy drivers}
  for I := 0 to Drivers.Count - 1 do
  begin
    Driver := Drivers.Items[I];

    if IsSameVersion(Driver, Result[0].Driver) then
    begin
      Inc(Found);
      Result[0].Driver.OemInf := Driver.OemInf;
      Result[0].Driver.Exists := True;
    end;

    if IsSameVersion(Driver, Result[1].Driver) then
    begin
      Inc(Found);
      Result[1].Driver.OemInf := Driver.OemInf;
      Result[1].Driver.Exists := True;
    end;

    if Found = 2 then
      Break;

  end;

end;

{Sets up legacy drivers}
function UserDriversGetLegacy: TUserDriverList;
begin

  Result[0].Delete := True;
  Result[0].Driver := UserDriversInit('Legacy PL2303 HXA/XA', LEGACY_HXA);

  Result[1].Delete := True;
  Result[1].Driver := UserDriversInit('Legacy PL2303 TA/TB', LEGACY_TAB);

end;

function UserDriversInit(DisplayName, Version: String): TDriverRec;
begin

  Result.Version := Version;
  StrToVersion(Version, Result.PackedVersion);
  Result.DisplayName := DisplayName;
  Result.Exists := False;

end;

function UserDriversGetInstalled: TPLDrivers;
var
  Output: TArrayOfString;
  Instances: TPLInstances;
  I, J, K: Integer;
  Instance: TInstanceRec;
  Driver: TDriverRec;
  Found: Boolean;

begin

  Debug('Seaching for installed PL2303 drivers');

  if not ExecPnpEnumDevices(False, Output) then
    Exit;

  Instances := GetPLInstances(Output);
  ParsePLInstances(Instances);

  {Returns unique list of installed drivers}
  for I := 0 to Instances.Count - 1 do
  begin
    Instance := Instances.Items[I];

    for J := 0 to Instance.Drivers.Count - 1 do
    begin
      Driver := Instance.Drivers.Items[J];
      Found := False;

      {See if we already have the driver}
      for K := 0 to Result.Count - 1 do
      begin
        Found := IsSameVersion(Driver, Result.Items[K]);

        if Found then
          Break;
      end;

      if not Found then
        AddToDriverList(Driver, Result);
    end;

  end;

end;

function UserDriversSelect(var List: TUserDriverList): Boolean;
var
  I: Integer;
  Count: Integer;
  Index: Integer;
  Driver: TDriverRec;

begin

  Result := False;
  Count := 0;

  for I := Low(List) to High(List) do
  begin

    if List[I].Driver.Exists then
      Inc(Count);

  end;

  if Count = 0 then
  begin
    Debug('No user drivers found');
    Exit;
  end;

  if UserDriversSilent then
    Exit;

  {Create the form}
  GUserForm := UserDriversCreateForm();

  try

    {Populate the listbox}
    for I := Low(List) to High(List)  do
    begin
      Driver := List[I].Driver;

      if not Driver.Exists then
        Continue;

      GUserForm.ListBox.AddCheckBox(Driver.DisplayName, Driver.Version, 0,
        True, True, False, False, TObject(I));
    end;

    {Show the form}
    GUserForm.Main.ShowModal();

    {Transfer checked items to Delete field}
    for I := 0 to GUserForm.ListBox.Items.Count - 1 do
    begin

      Index := Integer(GUserForm.ListBox.ItemObject[I]);
      List[Index].Delete := GUserForm.ListBox.Checked[I];

      if List[Index].Delete then
        Result := True;

    end;

    if Result then
      Debug('User chose to delete drivers')
    else
      Debug('User chose not to delete drivers');

  finally
    GUserForm.Main.Free();
  end;

end;

{Form can be tested by calling it from an installer script}
function UserDriversCreateForm: TDriverForm;
var
  Left: Integer;
  Width: Integer;
  Button: TButton;

begin

  Result.Main := CreateCustomForm();
  Result.Main.ClientWidth := ScaleX(300);
  Result.Main.ClientHeight := ScaleY(176);
  Result.Main.Caption := 'Remove legacy drivers';
  Result.Main.KeepSizeY := True;

  if IsUninstaller then
  begin
    Result.Main.Color := UninstallProgressForm.MainPanel.Color;
    Result.Main.FlipSizeAndCenterIfNeeded(True, UninstallProgressForm, False);
  end
  else
  begin
    Result.Main.Color := WizardForm.MainPanel.Color;
    Result.Main.FlipSizeAndCenterIfNeeded(True, WizardForm, False);
  end;

  Left := ScaleX(20);
  Width := Result.Main.ClientWidth - (Left * 2);

  Result.ListBox := TNewCheckListBox.Create(Result.Main);
  Result.ListBox.Top := ScaleY(16);
  Result.ListBox.Parent := Result.Main;
  Result.ListBox.Left := Left;
  Result.ListBox.Width := Width;
  Result.ListBox.Height := ScaleY(102);
  Result.ListBox.Flat := True;
  Result.ListBox.ParentColor := True;
  Result.ListBox.ShowLines := False;
  Result.ListBox.WantTabs := False;

  Button := TButton.Create(Result.Main);
  Button.Parent := Result.Main;
  Button.Top := Result.Main.ClientHeight - ScaleY(23 + 16);
  Button.Caption := '&OK';
  Button.Height := ScaleY(23);

  if IsUninstaller then
    Button.Width := UninstallProgressForm.CalculateButtonWidth([Button.Caption])
  else
    Button.Width := WizardForm.CalculateButtonWidth([Button.Caption]);

  Button.Left := Result.Main.ClientWidth - (Button.Width + Left);
  Button.ModalResult := mrOk;
  Button.Default := True;

  Result.Main.ActiveControl := Button;

end;

{Allows testing the form from an installer script}
function UserDriversSilent: Boolean;
begin

  if IsUninstaller then
    Result := UninstallSilent
  else
    Result := WizardSilent;

end;
