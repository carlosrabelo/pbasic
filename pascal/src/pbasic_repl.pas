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

end.
