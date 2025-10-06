unit pbasic_evaluator;

{$mode objfpc}{$H+}

interface

uses
  pbasic_token,
  pbasic_env,
  pbasic_program;

type
  PWord = ^Word;

  TEvaluator = class
  private
    FTokens: TTokenArray;
    FCursor: Integer;
    FVars: TVariableStore;
    FProg: TProgramStore;
    FRandSeed: PWord;

    function IsAtEnd: Boolean;
    function Current: TToken;
    function Advance: TToken;
    function Check(AType: TTokenType): Boolean;
    function Match(AType: TTokenType): Boolean;
  public
    constructor Create(const ATokens: TTokenArray; AVars: TVariableStore = nil; AProg: TProgramStore = nil; ARandSeed: PWord = nil);
    function GetCursor: Integer;
    procedure SetCursor(Val: Integer);

    function EvalFactor: LongInt;
    function EvalTerm: LongInt;
    function EvalExpression: LongInt;
    function EvalCondition: Boolean;
  end;

implementation

constructor TEvaluator.Create(const ATokens: TTokenArray; AVars: TVariableStore; AProg: TProgramStore; ARandSeed: PWord);
begin
  inherited Create;
  FTokens := ATokens;
  FCursor := 0;
  FVars := AVars;
  FProg := AProg;
  FRandSeed := ARandSeed;
end;

function TEvaluator.GetCursor: Integer;
begin
  Result := FCursor;
end;

procedure TEvaluator.SetCursor(Val: Integer);
begin
  FCursor := Val;
end;

function TEvaluator.IsAtEnd: Boolean;
begin
  Result := (FCursor >= Length(FTokens)) or
            (FTokens[FCursor].TokenType = ttEOL) or
            (FTokens[FCursor].TokenType = ttEOF);
end;

function TEvaluator.Current: TToken;
begin
  if FCursor < Length(FTokens) then
    Result := FTokens[FCursor]
  else
    Result := CreateToken(ttEOF);
end;

function TEvaluator.Advance: TToken;
begin
  if FCursor < Length(FTokens) then
  begin
    Result := FTokens[FCursor];
    Inc(FCursor);
  end
  else
    Result := CreateToken(ttEOF);
end;

function TEvaluator.Check(AType: TTokenType): Boolean;
begin
  Result := Current.TokenType = AType;
end;

function TEvaluator.Match(AType: TTokenType): Boolean;
begin
  if Check(AType) then
  begin
    Advance;
    Result := True;
  end
  else
    Result := False;
end;

function TEvaluator.EvalFactor: LongInt;
var
  X, Val: LongInt;
  RndVal: Word;
begin
  if Match(ttNumber) then
    Exit(FTokens[FCursor - 1].NumberVal);

  if Match(ttIdent) then
  begin
    if FVars <> nil then
      Exit(FVars.Get(FTokens[FCursor - 1].VarName))
    else
      Exit(0);
  end;

  if Match(ttFree) then
  begin
    if FProg <> nil then
      Exit(16384 - FProg.ByteSize)
    else
      Exit(16384);
  end;

  if Match(ttRnd) then
  begin
    Match(ttOpenParen);
    X := EvalExpression;
    Match(ttCloseParen);
    if FRandSeed <> nil then
    begin
      RndVal := NextRND(FRandSeed^);
      if X <= 0 then
        Exit(RndVal)
      else
        Exit((RndVal mod Word(X)) + 1);
    end;
    Exit(0);
  end;

  if Match(ttAbs) then
  begin
    Match(ttOpenParen);
    Val := EvalExpression;
    Match(ttCloseParen);
    Exit(Abs32(Val));
  end;

  if Match(ttOpenParen) then
  begin
    Val := EvalExpression;
    Match(ttCloseParen);
    Exit(Val);
  end;

  if Match(ttMinus) then
  begin
    Result := -EvalFactor();
    Exit;
  end;

  if Match(ttPlus) then
  begin
    Result := EvalFactor();
    Exit;
  end;

  Advance;
  Result := 0;
end;

function TEvaluator.EvalTerm: LongInt;
var
  Left, Right: LongInt;
  Op: TTokenType;
  ULeft, URight: Word;
begin
  Left := EvalFactor();

  while Check(ttStar) or Check(ttSlash) do
  begin
    Op := Advance.TokenType;
    Right := EvalFactor();

    ULeft := Word(Left and $FFFF);
    URight := Word(Right and $FFFF);

    if Op = ttStar then
      Left := Mul16(ULeft, URight)
    else
      Left := Div16(ULeft, URight);
  end;

  Result := Left;
end;

function TEvaluator.EvalExpression: LongInt;
begin
  Result := EvalTerm;
end;

function TEvaluator.EvalCondition: Boolean;
begin
  Result := EvalExpression <> 0;
end;

end.
