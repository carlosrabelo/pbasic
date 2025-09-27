unit pbasic_lexer;

{$mode objfpc}{$H+}

interface

uses
  pbasic_token;

type
  TLexer = class
  private
    FInput: string;
    FPos: Integer;
    procedure SkipWhitespace;
    function Peek: Char;
    function Advance: Char;
    function IsAtEnd: Boolean;
  public
    constructor Create(const AInput: string);
    function Tokenize: TTokenArray;
  end;

function Tokenize(const S: string): TTokenArray;

implementation

constructor TLexer.Create(const AInput: string);
begin
  inherited Create;
  FInput := AInput;
  FPos := 1;
end;

procedure TLexer.SkipWhitespace;
begin
  while (not IsAtEnd) and (FInput[FPos] in [' ', #9]) do
    Inc(FPos);
end;

function TLexer.Peek: Char;
begin
  if IsAtEnd then
    Result := #0
  else
    Result := FInput[FPos];
end;

function TLexer.Advance: Char;
begin
  if IsAtEnd then
    Result := #0
  else
  begin
    Result := FInput[FPos];
    Inc(FPos);
  end;
end;

function TLexer.IsAtEnd: Boolean;
begin
  Result := FPos > Length(FInput);
end;

function TLexer.Tokenize: TTokenArray;
var
  Tokens: TTokenArray;
  Count: Integer;

  procedure AddToken(ATok: TToken);
  begin
    Inc(Count);
    SetLength(Tokens, Count);
    Tokens[Count - 1] := ATok;
  end;

var
  Ch: Char;
begin
  SetLength(Tokens, 0);
  Count := 0;
  FPos := 1;

  while not IsAtEnd do
  begin
    SkipWhitespace;
    if IsAtEnd then
      Break;

    Ch := Advance;
    case Ch of
      '+': AddToken(CreateToken(ttPlus, '+'));
      '-': AddToken(CreateToken(ttMinus, '-'));
      '*': AddToken(CreateToken(ttStar, '*'));
      '/': AddToken(CreateToken(ttSlash, '/'));
      '(': AddToken(CreateToken(ttOpenParen, '('));
      ')': AddToken(CreateToken(ttCloseParen, ')'));
      ',': AddToken(CreateToken(ttComma, ','));
      ';': AddToken(CreateToken(ttSemicolon, ';'));
      ':': AddToken(CreateToken(ttColon, ':'));
      else
        AddToken(CreateToken(ttIllegal, Ch));
    end;
  end;

  AddToken(CreateToken(ttEOL, ''));
  Result := Tokens;
end;

function Tokenize(const S: string): TTokenArray;
var
  Lex: TLexer;
begin
  Lex := TLexer.Create(S);
  try
    Result := Lex.Tokenize;
  finally
    Lex.Free;
  end;
end;

end.
