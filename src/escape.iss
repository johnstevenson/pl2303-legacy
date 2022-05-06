[Code]

{This code section is included into the main script.
See https://github.com/johnstevenson/winbox-args for more information.}

function ArgCmd(Argument: String): String; forward;
function ArgCmdModule(Argument: String): String; forward;
function ArgWin(Argument: String): String; forward;
function EscapeArg(Argument: String; Meta, Module: Boolean): String; forward;
function EscapeBackslashes(Argument: String): String; forward;
function EscapeMeta(Argument: String): String; forward;
function EscapeQuotes(Argument: String; var Changed: Boolean): String; forward;
function IsExpandable(Argument: String): Boolean; forward;
function MatchChar(Needle, Haystack: String): Boolean; forward;


{Wrapper around EscapeArg, meta}
function ArgCmd(Argument: String): String;
begin
  Result := EscapeArg(Argument, True, False);
end;


{Wrapper around EscapeArg, meta, module}
function ArgCmdModule(Argument: String): String;
begin
  Result := EscapeArg(Argument, True, True);
end;


{Wrapper around EscapeArg}
function ArgWin(Argument: String): String;
begin
  Result := EscapeArg(Argument, False, False);
end;


{Escapes an argument for passing to Exec function. If Meta is True, cmd.exe
meta-characters will also be escaped. If Module is True, the argument is
treated as the module to be invoked, with extra edge-case checking.}
function EscapeArg(Argument: String; Meta, Module: Boolean): String;
var
  Quote: Boolean;
  DQuotes: Boolean;

begin

  Result := Argument;

  {Check for whitespace or an empty value}
  Quote := MatchChar(#32#9, Result) or (Result = '');

  {Escape double-quotes and double-up preceding backslashes}
  Result := EscapeQuotes(Result, DQuotes);

  if Meta then
  begin
    {Check for expansion %..% sequences}
    Meta := DQuotes or IsExpandable(Result);

    if not Meta then
      {Check for characters that can be escaped in quotes}
      Quote := Quote or MatchChar('^&|<>()', Result)

    else if not DQuotes and Quote and Module then
      {Caret-escaping a module name with whitespace will split the
      argument, so just quote it and hope there is no expansion}
      Meta := False;

  end;

  if Quote then
  begin
    {Double-up trailing backslashes and enclose in double-quotes}
    Result := EscapeBackslashes(Result);
    Result := '"' + Result + '"';
  end;

  if Meta then
    {Caret-escape all meta characters}
    Result := EscapeMeta(Result);

end;


{Backslash-escapes consecutive backslashes at the end of the argument.}
function EscapeBackslashes(Argument: String): String;
var
  Start: Integer;
  Count: Integer;

begin

  Result := Argument;
  Count := 0;

  for Start := Length(Argument) downto 1 do
  begin

    if Argument[Start] = '\' then
      Inc(Count)
    else
    begin

      if Count > 0 then
        Insert(StringOfChar('\', Count), Result, Start + 1);

      Break;
    end;
  end;

end;


{Escapes meta chararcters with a caret.}
function EscapeMeta(Argument: String): String;
var
  ToEscape: String;
  I: Integer;

begin

  Result := Argument;

  {The caret must come first or we will double escape them}
  ToEscape := '^"&|<>()%';

  for I := 1 to Length(ToEscape) do
    StringChangeEx(Result, ToEscape[I], '^' + ToEscape[I], True);

end;


{Escapes double-quotes and doubles-up preceding backslashes. Changed is set to
True if double-quotes were found.}
function EscapeQuotes(Argument: String; var Changed: Boolean): String;
var
  Index: Integer;
  Item: String;
  Remainder: String;

begin

  Result := '';
  Changed := False;
  Remainder := Argument;

  repeat
    Index := Pos('"', Remainder);

    if Index = 0 then
      Result := Result + Remainder
    else
    begin
      Item := Copy(Remainder, 1, Index - 1);
      Delete(Remainder, 1, Index);
      Result := Result + EscapeBackslashes(Item) + '\"';
      Changed := True;
    end;
  until Index = 0;

end;


{Returns True if an argument contains surrounding % characters.}
function IsExpandable(Argument: String): Boolean;
var
  Open: Integer;
  Close: Integer;

begin

  Result := False;

  Open := Pos('%', Argument);
  if Open = 0 then
    Exit;

  Close := Pos('%', Copy(Argument, Open + 1, MaxInt));
  Result := Close > 1;
end;


{Returns True if a character in needle is found in Haystack}
function MatchChar(Needle, Haystack: String): Boolean;
var
  I: Integer;

begin

  Result := False;

  if Haystack = '' then
    Exit;

  for I := 1 to Length(Needle) do
  begin

    if Pos(Needle[I], Haystack) > 0 then
    begin
      Result := True;
      Exit;
    end;

  end;
end;


{Tests. Uncomment the code block below and run TestEscape from somewhere in the
main script. An Exception is raised on a failure}

{
procedure CheckTest(Test, Expected, Actual: String);
begin
  if (Actual <> Expected) then
    RaiseException(Test + ' does not match expected ' + Expected);
end;

procedure TestEscape;
var
  Argument: String;
  Expected: String;

begin

  //Win tests
  Argument := '';
  Expected := '""';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'a b c';
  Expected := '"a b c"';
  CheckTest(Argument, Expected, ArgWin(Argument));


  Argument := 'a' + #9 + 'b' + #9 + 'c';
  Expected := '"a' + #9 + 'b' + #9 + 'c"';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'abc';
  Expected := 'abc';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'a"bc';
  Expected := 'a\"bc';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'a\\"bc';
  Expected := 'a\\\\\"bc';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'ab\\\\c\\';
  Expected := 'ab\\\\c\\';
  CheckTest(Argument, Expected, ArgWin(Argument));

  Argument := 'a b c\\\\';
  Expected := '"a b c\\\\\\\\"';
  CheckTest(Argument, Expected, ArgWin(Argument));

  //Meta tests
  Argument := 'a"bc';
  Expected := 'a\^"bc';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := 'a "b" c';
  Expected := '^"a \^"b\^" c^"';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '%path%';
  Expected := '^%path^%';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '%path';
  Expected := '%path';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '%%path';
  Expected := '%%path';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '!path!';
  Expected := '!path!';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '<>"&|()^';
  Expected := '^<^>\^"^&^|^(^)^^';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '<> &| ()^';
  Expected := '"<> &| ()^"';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := '<>&|()^';
  Expected := '"<>&|()^"';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := 'path\A&A\folder';
  Expected := '"path\A&A\folder"';
  CheckTest(Argument, Expected, ArgCmd(Argument));

  Argument := 'very daft\%folder name%\file';
  Expected := '^"very daft\^%folder name^%\file^"';
  CheckTest(Argument, Expected, ArgCmd(Argument));


  //Module tests
  Argument := 'very daft\%folder name%\file';
  Expected := '"very daft\%folder name%\file"';
  CheckTest(Argument, Expected, ArgCmdModule(Argument));

end;
}
