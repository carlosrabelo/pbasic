program pbasic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  pbasic_signals,
  pbasic_token,
  pbasic_lexer,
  pbasic_program,
  pbasic_env,
  pbasic_interpreter,
  pbasic_repl;

var
  Prog: TProgramStore;
  Vars: TVariableStore;
  Interp: TInterpreter;
  FilePath: string;
  F: Text;
  RawLine, Folded: string;
  Prefix: TParsedLinePrefix;

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

    Prog := TProgramStore.Create;
    Vars := TVariableStore.Create;
    Interp := TInterpreter.Create(Prog, Vars, 12345);

    Assign(F, FilePath);
    Reset(F);
    while not Eof(F) do
    begin
      ReadLn(F, RawLine);
      if (Length(RawLine) > 0) and (RawLine[Length(RawLine)] = #13) then
        Delete(RawLine, Length(RawLine), 1);
      Folded := FoldCase(RawLine);
      Prefix := ClassifyLine(Folded);
      if Prefix.LineType = ltNumbered then
      begin
        Prog.SetLine(Prefix.LineNumber, Tokenize(Prefix.Content), Prefix.Content);
      end
      else if Prefix.LineType = ltImmediate then
      begin
        Interp.ExecuteStatement(Tokenize(Prefix.Content));
      end;
    end;
    Close(F);

    Interp.RunProgram;

    Interp.Free;
    Prog.Free;
    Vars.Free;
    Halt(0);
  end;

  StartREPL;
end.
