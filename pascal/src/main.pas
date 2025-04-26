program pbasic;

{$mode objfpc}{$H+}

uses
  SysUtils, pbasic_signals, pbasic_repl;

var
  FilePath: string;

begin
  InstallSignalHandlers;

  if ParamCount >= 1 then
  begin
    FilePath := ParamStr(1);
    if not FileExists(FilePath) then
    begin
      writeln(StdErr, 'Cannot open file: ', FilePath);
      Halt(1);
    end;
    // Batch file mode (implemented in later tasks)
    Halt(0);
  end;

  StartREPL;
end.
