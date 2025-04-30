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
    function ReadIdentifier: string;
    function ReadRestOfLine: string;
    function ReadNumber: TToken;
    function ReadString: TToken;
  public
    constructor Create(const AInput: string);
    function Tokenize: TTokenArray;
  end;

function Tokenize(const S: string): TTokenArray;
function Detokenize(const Tokens: TTokenArray): string;

implementation

uses
  SysUtils;

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

function TLexer.ReadIdentifier: string;
var
  S: string;
begin
  S := '';
  while (not IsAtEnd) and (Peek in ['A'..'Z']) do
    S := S + Advance;
  Result := S;
end;

function TLexer.ReadRestOfLine: string;
begin
  if IsAtEnd then
    Result := ''
  else
  begin
    Result := Copy(FInput, FPos, Length(FInput) - FPos + 1);
    FPos := Length(FInput) + 1;
  end;
end;

function TLexer.ReadNumber: TToken;
var
  NumStr: string;
  Val: Int64;
  Digit: Char;
begin
  NumStr := '';
  Val := 0;
  while (not IsAtEnd) and (Peek in ['0'..'9']) do
  begin
    Digit := Advance;
    NumStr := NumStr + Digit;
    Val := Val * 10 + (Ord(Digit) - Ord('0'));
  end;
  Result := CreateNumberToken(LongInt(Val), NumStr);
end;

function TLexer.ReadString: TToken;
var
  StrContent: string;
begin
  StrContent := '';
  Advance; // Skip opening quote
  while (not IsAtEnd) and (Peek <> '"') do
    StrContent := StrContent + Advance;
  if (not IsAtEnd) and (Peek = '"') then
    Advance; // Skip closing quote
  Result := CreateStringToken(StrContent);
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
  Ident, Comment: string;
begin
  SetLength(Tokens, 0);
  Count := 0;
  FPos := 1;

  while not IsAtEnd do
  begin
    SkipWhitespace;
    if IsAtEnd then
      Break;

    Ch := Peek;
    if Ch in ['A'..'Z'] then
    begin
      Ident := ReadIdentifier;
      if Ident = 'LET' then AddToken(CreateToken(ttLet, 'LET'))
      else if Ident = 'GOTO' then AddToken(CreateToken(ttGoto, 'GOTO'))
      else if Ident = 'GOSUB' then AddToken(CreateToken(ttGosub, 'GOSUB'))
      else if Ident = 'PRINT' then AddToken(CreateToken(ttPrint, 'PRINT'))
      else if Ident = 'IF' then AddToken(CreateToken(ttIf, 'IF'))
      else if Ident = 'INPUT' then AddToken(CreateToken(ttInput, 'INPUT'))
      else if Ident = 'RETURN' then AddToken(CreateToken(ttReturn, 'RETURN'))
      else if Ident = 'END' then AddToken(CreateToken(ttEnd, 'END'))
      else if Ident = 'LIST' then AddToken(CreateToken(ttList, 'LIST'))
      else if Ident = 'RUN' then AddToken(CreateToken(ttRun, 'RUN'))
      else if Ident = 'NEW' then AddToken(CreateToken(ttNew, 'NEW'))
      else if Ident = 'EXIT' then AddToken(CreateToken(ttExit, 'EXIT'))
      else if Ident = 'THEN' then AddToken(CreateToken(ttThen, 'THEN'))
      else if Ident = 'FREE' then AddToken(CreateToken(ttFree, 'FREE'))
      else if Ident = 'RND' then AddToken(CreateToken(ttRnd, 'RND'))
      else if Ident = 'ABS' then AddToken(CreateToken(ttAbs, 'ABS'))
      else if Ident = 'REM' then
      begin
        SkipWhitespace;
        Comment := ReadRestOfLine;
        AddToken(CreateToken(ttRem, Comment));
      end
      else if Length(Ident) = 1 then
        AddToken(CreateIdentToken(Ident[1]))
      else
        AddToken(CreateToken(ttIllegal, Ident));
      Continue;
    end;

    if Ch in ['0'..'9'] then
    begin
      AddToken(ReadNumber);
      Continue;
    end;

    if Ch = '"' then
    begin
      AddToken(ReadString);
      Continue;
    end;

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
      '=':
      begin
        if Peek = '=' then
        begin
          Advance;
          AddToken(CreateToken(ttEq, '=='));
        end
        else
          AddToken(CreateToken(ttEq, '='));
      end;
      '<':
      begin
        if Peek = '>' then
        begin
          Advance;
          AddToken(CreateToken(ttNotEq, '<>'));
        end
        else if Peek = '=' then
        begin
          Advance;
          AddToken(CreateToken(ttLtEq, '<='));
        end
        else
          AddToken(CreateToken(ttLt, '<'));
      end;
      '>':
      begin
        if Peek = '=' then
        begin
          Advance;
          AddToken(CreateToken(ttGtEq, '>='));
        end
        else
          AddToken(CreateToken(ttGt, '>'));
      end;
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

function Detokenize(const Tokens: TTokenArray): string;
var
  S: string;
  I: Integer;
  Tok: TToken;
begin
  S := '';
  for I := 0 to High(Tokens) do
  begin
    Tok := Tokens[I];
    case Tok.TokenType of
      ttLet: S := S + 'LET ';
      ttGoto: S := S + 'GOTO ';
      ttGosub: S := S + 'GOSUB ';
      ttPrint: S := S + 'PRINT ';
      ttIf: S := S + 'IF ';
      ttInput: S := S + 'INPUT ';
      ttReturn: S := S + 'RETURN';
      ttEnd: S := S + 'END';
      ttList: S := S + 'LIST';
      ttRun: S := S + 'RUN';
      ttNew: S := S + 'NEW';
      ttExit: S := S + 'EXIT';
      ttRem:
      begin
        S := S + 'REM ' + Tok.Literal;
      end;
      ttThen: S := S + ' THEN ';
      ttFree: S := S + 'FREE';
      ttRnd: S := S + 'RND';
      ttAbs: S := S + 'ABS';
      ttNumber: S := S + IntToStr(Tok.NumberVal);
      ttString: S := S + '"' + Tok.Literal + '"';
      ttIdent: S := S + Tok.VarName;
      ttPlus: S := S + ' + ';
      ttMinus:
      begin
        if (Length(S) = 0) or (S[Length(S)] = '(') or (S[Length(S)] = ' ') then
          S := S + '-'
        else
          S := S + ' - ';
      end;
      ttStar: S := S + ' * ';
      ttSlash: S := S + ' / ';
      ttEq: S := S + ' = ';
      ttNotEq: S := S + ' <> ';
      ttLt: S := S + ' < ';
      ttGt: S := S + ' > ';
      ttLtEq: S := S + ' <= ';
      ttGtEq: S := S + ' >= ';
      ttOpenParen: S := S + '(';
      ttCloseParen: S := S + ')';
      ttComma: S := S + ', ';
      ttSemicolon: S := S + '; ';
      ttColon: S := S + ' : ';
      ttEOL, ttEOF, ttIllegal: ;
    end;
  end;
  Result := S;
end;

end.
