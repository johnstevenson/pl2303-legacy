; This file is only included in release builds

; release defines
#define private OutputDir "..\builds\release"
#define private OutputBaseFilename AppFileName + "." + SetupVersion

; release guard
#if FileExists(OutputDir + "\" + OutputBaseFilename + ".exe")
  #pragma error "Version " + SetupVersion + " has already been released"
#endif

[Setup]
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
SignTool={#SignTool} {#SignExe} {#SignSha2} $f
