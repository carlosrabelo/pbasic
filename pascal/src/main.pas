program pbasic;

{$mode objfpc}{$H+}

uses
  SysUtils;

var
  FilePath: string;

begin
  if ParamCount >= 1 then
  begin
    FilePath := ParamStr(1);
    if not FileExists(FilePath) then
    begin
      writeln(StdErr, 'Cannot open file: ', FilePath);
      Halt(1);
    end;
    // Batch file mode
    Halt(0);
  end;

  // Interactive mode banner
  writeln('PBasic');
end.
