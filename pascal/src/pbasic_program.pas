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
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Empty: Boolean;
    function LineCount: Integer;
    function HasLine(LineNo: Word): Boolean;
    function GetLine(LineNo: Word; out Tokens: TTokenArray; out RawText: string): Boolean;
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

end.
