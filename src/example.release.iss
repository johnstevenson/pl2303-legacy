#define Release

#include "config.iss"

; The unique name you add to the Inno Setup IDE, using the Tools menu.
; Click Configure Sign Tools, then Add to enter your unique name, then
; enter $p as the command (the $p is replaced by the actual parameters).
#define SignTool "uniquename"

; The full path to signtool.exe enclosed in inner doube-quotes and outer single-quotes.
; This Microsoft tool is in the Windows SDK and can be found using the Visual Studio
; Developer Command Prompt and typing 'where signtool'.
#define SignExe '"path\to\signtool.exe"'

; Use sh256 signature
#define SignSha2 "sign /a /fd sha256 /tr http://time.certum.pl/ /td sha256 /as"

[Setup]
SignTool={#SignTool} {#SignExe} {#SignSha2} $f

#include "pl2303.iss"
