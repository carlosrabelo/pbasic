unit pbasic_program;

{$mode objfpc}{$H+}

interface

uses
  pbasic_token;

type
  TProgramLine = record
    LineNumber: Word;
    Tokens: TTokenArray;
    RawText: string;
  end;

  TProgram = class
  private
    FLines: array of TProgramLine;
    function FindIndex(LineNo: Word): Integer;
    function FindInsertIndex(LineNo: Word): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Empty: Boolean;
    function LineCount: Integer;
    function HasLine(LineNo: Word): Boolean;
    function GetLine(LineNo: Word; out Tokens: TTokenArray; out RawText: string): Boolean;
    procedure SetLine(LineNo: Word; const Tokens: TTokenArray; const RawText: string = '');
    function RemoveLine(LineNo: Word): Boolean;
  end;

implementation

constructor TProgram.Create;
begin
  inherited Create;
  Clear;
end;

destructor TProgram.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TProgram.Clear;
begin
  SetLength(FLines, 0);
end;

function TProgram.Empty: Boolean;
begin
  Result := Length(FLines) = 0;
end;

function TProgram.LineCount: Integer;
begin
  Result := Length(FLines);
end;

function TProgram.FindIndex(LineNo: Word): Integer;
var
  LowIdx, HighIdx, Mid: Integer;
begin
  LowIdx := 0;
  HighIdx := High(FLines);
  while LowIdx <= HighIdx do
  begin
    Mid := (LowIdx + HighIdx) div 2;
    if FLines[Mid].LineNumber = LineNo then
      Exit(Mid)
    else if FLines[Mid].LineNumber < LineNo then
      LowIdx := Mid + 1
    else
      HighIdx := Mid - 1;
  end;
  Result := -1;
end;

function TProgram.HasLine(LineNo: Word): Boolean;
begin
  Result := FindIndex(LineNo) >= 0;
end;

function TProgram.GetLine(LineNo: Word; out Tokens: TTokenArray; out RawText: string): Boolean;
var
  Idx: Integer;
begin
  Idx := FindIndex(LineNo);
  if Idx < 0 then
  begin
    SetLength(Tokens, 0);
    RawText := '';
    Exit(False);
  end;
  Tokens := FLines[Idx].Tokens;
  RawText := FLines[Idx].RawText;
  Result := True;
end;

function TProgram.FindInsertIndex(LineNo: Word): Integer;
var
  LowIdx, HighIdx, Mid: Integer;
begin
  LowIdx := 0;
  HighIdx := High(FLines);
  while LowIdx <= HighIdx do
  begin
    Mid := (LowIdx + HighIdx) div 2;
    if FLines[Mid].LineNumber = LineNo then
      Exit(Mid)
    else if FLines[Mid].LineNumber < LineNo then
      LowIdx := Mid + 1
    else
      HighIdx := Mid - 1;
  end;
  Result := LowIdx;
end;

procedure TProgram.SetLine(LineNo: Word; const Tokens: TTokenArray; const RawText: string);
var
  Idx, I, OldLen: Integer;
begin
  if (Length(Tokens) = 0) or ((Length(Tokens) = 1) and (Tokens[0].TokenType = ttEOL)) then
  begin
    RemoveLine(LineNo);
    Exit;
  end;

  Idx := FindIndex(LineNo);
  if Idx >= 0 then
  begin
    FLines[Idx].Tokens := Tokens;
    FLines[Idx].RawText := RawText;
    Exit;
  end;

  Idx := FindInsertIndex(LineNo);
  OldLen := Length(FLines);
  SetLength(FLines, OldLen + 1);
  for I := OldLen downto Idx + 1 do
    FLines[I] := FLines[I - 1];

  FLines[Idx].LineNumber := LineNo;
  FLines[Idx].Tokens := Tokens;
  FLines[Idx].RawText := RawText;
end;

function TProgram.RemoveLine(LineNo: Word): Boolean;
var
  Idx, I: Integer;
begin
  Idx := FindIndex(LineNo);
  if Idx < 0 then
    Exit(False);

  for I := Idx to High(FLines) - 1 do
    FLines[I] := FLines[I + 1];
  SetLength(FLines, Length(FLines) - 1);
  Result := True;
end;

end.
