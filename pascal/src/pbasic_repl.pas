unit pbasic_repl;

{$mode objfpc}{$H+}

interface

type
  TLineType = (ltEmpty, ltNumbered, ltImmediate);

  TParsedLinePrefix = record
    LineType: TLineType;
    LineNumber: Word;
    Content: string;
  end;

procedure PrintStr(var F: Text; const S: string); overload;
procedure PrintStr(const S: string); overload;

procedure PrintNumber(var F: Text; N: LongInt); overload;
procedure PrintNumber(N: LongInt); overload;

procedure PrintCRLF(var F: Text); overload;
procedure PrintCRLF; overload;

procedure PrintOK(var F: Text); overload;
procedure PrintOK; overload;

function FoldCase(const S: string): string;
function ClassifyLine(const S: string): TParsedLinePrefix;
function ReadLine(var F: Text; var S: string): Boolean; overload;
function ReadLine(var S: string): Boolean; overload;

procedure StartREPL(var InFile, OutFile: Text); overload;
procedure StartREPL; overload;

implementation

uses
  SysUtils,
  pbasic_signals,
  pbasic_token,
  pbasic_lexer,
  pbasic_program,
  pbasic_env,
  pbasic_interpreter;

procedure PrintStr(var F: Text; const S: string);
begin
  write(F, S);
end;

procedure PrintStr(const S: string);
begin
  write(Output, S);
end;

procedure PrintNumber(var F: Text; N: LongInt);
begin
  write(F, N);
end;

procedure PrintNumber(N: LongInt);
begin
  write(Output, N);
end;

procedure PrintCRLF(var F: Text);
begin
  writeln(F);
end;

procedure PrintCRLF;
begin
  writeln(Output);
end;

procedure PrintOK(var F: Text);
begin
  writeln(F, 'OK');
end;

procedure PrintOK;
begin
  writeln(Output, 'OK');
end;

function FoldCase(const S: string): string;
var
  I: Integer;
  InQuotes: Boolean;
  C: Char;
begin
  Result := '';
  InQuotes := False;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if C = '"' then
      InQuotes := not InQuotes
    else if (not InQuotes) and (C in ['a'..'z']) then
      C := UpCase(C);
    Result := Result + C;
  end;
end;

function ClassifyLine(const S: string): TParsedLinePrefix;
var
  Trimmed, Rest: string;
  Idx: Integer;
  Num: Int64;
begin
  Trimmed := Trim(S);
  if Trimmed = '' then
  begin
    Result.LineType := ltEmpty;
    Result.LineNumber := 0;
    Result.Content := '';
    Exit;
  end;

  if (Trimmed[1] in ['0'..'9']) then
  begin
    Idx := 1;
    Num := 0;
    while (Idx <= Length(Trimmed)) and (Trimmed[Idx] in ['0'..'9']) do
    begin
      Num := Num * 10 + (Ord(Trimmed[Idx]) - Ord('0'));
      if Num > 65535 then
        Break;
      Inc(Idx);
    end;

    if (Num >= 1) and (Num <= 65535) then
    begin
      Rest := Trim(Copy(Trimmed, Idx, Length(Trimmed) - Idx + 1));
      Result.LineType := ltNumbered;
      Result.LineNumber := Word(Num);
      Result.Content := Rest;
      Exit;
    end;
  end;

  Result.LineType := ltImmediate;
  Result.LineNumber := 0;
  Result.Content := Trimmed;
end;

function ReadLine(var F: Text; var S: string): Boolean;
begin
  if Eof(F) then
    Exit(False);
  ReadLn(F, S);
  if (Length(S) > 0) and (S[Length(S)] = #13) then
    Delete(S, Length(S), 1);
  S := FoldCase(S);
  Result := True;
end;

function ReadLine(var S: string): Boolean;
begin
  Result := ReadLine(Input, S);
end;

procedure StartREPL(var InFile, OutFile: Text);
var
  Line, Trimmed: string;
  Prog: TProgramStore;
  Vars: TVariableStore;
  Interp: TInterpreter;
  Prefix: TParsedLinePrefix;
  Toks: TTokenArray;
begin
  Prog := TProgramStore.Create;
  Vars := TVariableStore.Create;
  Interp := TInterpreter.Create(Prog, Vars, 12345);

  writeln(OutFile, 'PBasic');
  write(OutFile, '> ');
  Flush(OutFile);

  while True do
  begin
    if CheckAndResetInterrupted then
    begin
      writeln(OutFile);
      write(OutFile, '> ');
      Flush(OutFile);
    end;

    if not ReadLine(InFile, Line) then
      Break;

    Prefix := ClassifyLine(Line);
    if Prefix.LineType = ltNumbered then
    begin
      Trimmed := Trim(Prefix.Content);
      if Length(Trimmed) = 0 then
        Prog.RemoveLine(Prefix.LineNumber)
      else
        Prog.SetLine(Prefix.LineNumber, Tokenize(Prefix.Content), Prefix.Content);
    end
    else if Prefix.LineType = ltImmediate then
    begin
      Toks := Tokenize(Prefix.Content);
      Interp.ExecuteStatement(Toks);
      if Interp.ExitRequested then
        Break;
    end;

    write(OutFile, '> ');
    Flush(OutFile);
  end;

  Interp.Free;
  Prog.Free;
  Vars.Free;
end;

procedure StartREPL;
begin
  StartREPL(Input, Output);
end;

end.
