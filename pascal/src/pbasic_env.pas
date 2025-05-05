unit pbasic_env;

{$mode objfpc}{$H+}

interface

type
  TVariableStore = class
  private
    FVars: array['A'..'Z'] of LongInt;
  public
    constructor Create;
    procedure Clear;
    function Count: Integer;
    function Get(Name: Char): LongInt;
    procedure SetVal(Name: Char; Value: LongInt);
    function GetVar(Name: Char): LongInt;
    procedure SetVar(Name: Char; Value: LongInt);
  end;

function Mul16(A, B: LongInt): LongInt;
function Div16(A, B: LongInt): LongInt;
function Mod16(A, B: LongInt): LongInt;
function Add32(A, B: LongInt): LongInt;
function Sub32(A, B: LongInt): LongInt;
function Neg32(A: LongInt): LongInt;
function NextRND(var Seed: Word): Word;
function Abs32(A: LongInt): LongInt;

implementation

constructor TVariableStore.Create;
begin
  inherited Create;
  Clear;
end;

procedure TVariableStore.Clear;
var
  C: Char;
begin
  for C := 'A' to 'Z' do
    FVars[C] := 0;
end;

function TVariableStore.Count: Integer;
begin
  Result := 26;
end;

function TVariableStore.Get(Name: Char): LongInt;
var
  C: Char;
begin
  C := UpCase(Name);
  if C in ['A'..'Z'] then
    Result := FVars[C]
  else
    Result := 0;
end;

procedure TVariableStore.SetVal(Name: Char; Value: LongInt);
var
  C: Char;
begin
  C := UpCase(Name);
  if C in ['A'..'Z'] then
    FVars[C] := Value;
end;

function TVariableStore.GetVar(Name: Char): LongInt;
begin
  Result := Get(Name);
end;

procedure TVariableStore.SetVar(Name: Char; Value: LongInt);
begin
  SetVal(Name, Value);
end;

function Mul16(A, B: LongInt): LongInt;
begin
  Result := (LongWord(Word(A)) * LongWord(Word(B))) and $FFFF;
end;

function Div16(A, B: LongInt): LongInt;
var
  UA, UB: Word;
begin
  UA := Word(A);
  UB := Word(B);
  if UB = 0 then
    Result := $FFFF
  else
    Result := UA div UB;
end;

function Mod16(A, B: LongInt): LongInt;
var
  UA, UB: Word;
begin
  UA := Word(A);
  UB := Word(B);
  if UB = 0 then
    Result := UA
  else
    Result := UA mod UB;
end;

function Add32(A, B: LongInt): LongInt;
begin
  Result := A + B;
end;

function Sub32(A, B: LongInt): LongInt;
begin
  Result := A - B;
end;

function Neg32(A: LongInt): LongInt;
begin
  Result := -A;
end;

function NextRND(var Seed: Word): Word;
begin
  Seed := (LongWord(Seed) * 25173 + 13849) and $FFFF;
  Result := Seed;
end;

function Abs32(A: LongInt): LongInt;
begin
  if A < 0 then
    Result := -A
  else
    Result := A;
end;

end.
