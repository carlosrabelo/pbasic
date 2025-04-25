unit pbasic_repl;

{$mode objfpc}{$H+}

interface

procedure PrintStr(var F: Text; const S: string); overload;
procedure PrintStr(const S: string); overload;

procedure PrintNumber(var F: Text; N: LongInt); overload;
procedure PrintNumber(N: LongInt); overload;

procedure PrintCRLF(var F: Text); overload;
procedure PrintCRLF; overload;

procedure PrintOK(var F: Text); overload;
procedure PrintOK; overload;

function FoldCase(const S: string): string;
function ReadLine(var F: Text; var S: string): Boolean; overload;
function ReadLine(var S: string): Boolean; overload;

implementation

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

end.
